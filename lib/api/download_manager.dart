import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/stream_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadManager {
  static final ValueNotifier<List<DownloadEntry>> items = ValueNotifier(
    const [],
  );
  static bool _busy = false;
  static bool _loaded = false;
  static Future<void> _writes = Future.value();
  static Future<void>? _metadataRefresh;
  static final _cancellations = <String, CancelToken>{};
  static final _jobs = <String, Future<void>>{};
  static final _removed = <String>{};

  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _indexFile() async {
    final dir = await _dir();
    return File('${dir.path}/index.json');
  }

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _indexFile();
      if (!await file.exists()) return;
      final raw = jsonDecode(await file.readAsString()) as List<dynamic>;
      items.value = raw
          .map(
            (row) =>
                DownloadEntry.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (_) {}
  }

  static Future<void> _persist() {
    final json = jsonEncode(items.value.map((e) => e.toJson()).toList());
    return _writes = _writes.catchError((Object _) {}).then((_) async {
      final file = await _indexFile();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(json, flush: true);
      await temporary.rename(file.path);
    });
  }

  static Future<void> setPlaybackProgress(String id, double completion) async {
    final entry = items.value.where((item) => item.id == id).firstOrNull;
    if (entry == null) return;
    entry.playbackProgress = completion.clamp(0, 1);
    items.value = [...items.value];
    await _persist();
  }

  static Future<void> refreshMetadata() {
    if (!BackendApi.authState.loggedIn) return Future.value();
    if (!items.value.any(
      (entry) =>
          entry.mediaTitle == null ||
          (entry.isShow && entry.episodeTitle == null),
    ))
      return Future.value();
    return _metadataRefresh ??= () async {
      for (final entry in [...items.value]) {
        await _loadMetadata(entry);
      }
      items.value = [...items.value];
      await _persist();
    }().whenComplete(() => _metadataRefresh = null);
  }

  static Future<void> _loadMetadata(DownloadEntry entry) async {
    if (entry.mediaTitle != null &&
        (!entry.isShow || entry.episodeTitle != null))
      return;
    try {
      if (entry.isShow) {
        entry.mediaTitle = (await TMDB.tvShow(entry.tmdbId)).name;
        entry.episodeTitle = (await TMDB.tvEpisode(
          entry.tmdbId,
          entry.season!,
          entry.episode!,
        )).name;
      } else {
        entry.mediaTitle = (await TMDB.movie(entry.tmdbId)).title;
      }
    } catch (_) {
      /* Keep saved labels when metadata is unavailable. */
    }
  }

  static bool canSave(String url) {
    final lower = url.toLowerCase();
    if (url.isEmpty) return false;
    if (lower.startsWith('magnet:')) return false;
    if (lower.contains('infohash')) return false;
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('file://');
  }

  static String _id({required int tmdbId, int? season, int? episode}) {
    return season == null ? 'movie-$tmdbId' : 'show-$tmdbId-$season-$episode';
  }

  static DownloadEntry? find({required int tmdbId, int? season, int? episode}) {
    final id = _id(tmdbId: tmdbId, season: season, episode: episode);
    for (final item in items.value) {
      if (item.id == id) return item;
    }
    return null;
  }

  static Future<void> enqueueStream({
    required StreamItem stream,
    required int tmdbId,
    required String title,
    int? season,
    int? episode,
    String? mediaTitle,
    String? episodeTitle,
  }) async {
    await load();
    if (!canSave(stream.url)) {
      throw Exception('This source cannot be saved on device.');
    }
    final id = _id(tmdbId: tmdbId, season: season, episode: episode);
    final existing = [...items.value];
    _removed.remove(id);
    final index = existing.indexWhere((item) => item.id == id);
    final entry = DownloadEntry(
      id: id,
      title: title,
      tmdbId: tmdbId,
      season: season,
      episode: episode,
      url: stream.url,
      status: DownloadStatus.queued,
      mediaTitle: mediaTitle,
      episodeTitle: episodeTitle,
    );
    if (index >= 0) {
      existing[index] = entry;
    } else {
      existing.insert(0, entry);
    }
    items.value = existing;
    await _persist();
    _pump();
  }

  static Future<void> enqueueEpisode({
    required int tmdbId,
    required String title,
    required int season,
    required int episode,
  }) async {
    await load();
    final id = _id(tmdbId: tmdbId, season: season, episode: episode);
    if (items.value.any(
      (item) => item.id == id && item.status != DownloadStatus.failed,
    ))
      return;
    _removed.remove(id);
    items.value = [
      DownloadEntry(
        id: id,
        title: title,
        tmdbId: tmdbId,
        season: season,
        episode: episode,
      ),
      ...items.value.where((item) => item.id != id),
    ];
    await _persist();
    _pump();
  }

  static Future<void> enqueueSeason({
    required int tmdbId,
    required String showName,
    required int season,
    required List<int> episodes,
  }) async {
    for (final episode in episodes) {
      await enqueueEpisode(
        tmdbId: tmdbId,
        title: '$showName S$season:E$episode',
        season: season,
        episode: episode,
      );
    }
  }

  static Future<void> remove(String id) async {
    _removed.add(id);
    _cancellations[id]?.cancel('Download deleted');
    await _jobs[id];
    final entry = items.value.where((item) => item.id == id).firstOrNull;
    if (entry?.path != null) {
      final file = File(entry!.path!);
      if (await file.exists()) await file.delete();
    }
    items.value = items.value.where((item) => item.id != id).toList();
    await _persist();
  }

  static Future<void> _pump() async {
    if (_busy) return;
    _busy = true;
    try {
      while (true) {
        final queued = items.value
            .where((item) => item.status == DownloadStatus.queued)
            .firstOrNull;
        if (queued == null) break;
        final job = _run(queued);
        _jobs[queued.id] = job;
        try {
          await job;
        } finally {
          _jobs.remove(queued.id);
          _cancellations.remove(queued.id);
        }
      }
    } finally {
      _busy = false;
    }
  }

  static void _update(DownloadEntry entry) {
    items.value = [
      for (final item in items.value) item.id == entry.id ? entry : item,
    ];
    _persist();
  }

  static Future<void> _run(DownloadEntry entry) async {
    entry.status = DownloadStatus.running;
    _update(entry);
    try {
      var url = entry.url;
      if (url == null || Uri.tryParse(url)?.scheme != 'file')
        await _loadMetadata(entry);
      if (url == null || url.isEmpty) {
        final show = entry.season != null;
        final details = show
            ? await TMDB.tvShow(entry.tmdbId)
            : await TMDB.movie(entry.tmdbId);
        final imdb = (details as dynamic).imdbId as String?;
        if (imdb == null || imdb.isEmpty) {
          entry.status = DownloadStatus.unavailable;
          entry.error = 'Missing IMDb id';
          _update(entry);
          return;
        }
        final streams = await StreamApi.fetchStreams(
          imdb,
          show
              ? Episode(
                  seasonNumber: entry.season!,
                  episodeNumber: entry.episode!,
                )
              : null,
        );
        final match = streams
            .where((stream) => !stream.external && canSave(stream.url))
            .firstOrNull;
        if (match == null) {
          entry.status = DownloadStatus.unavailable;
          entry.error = 'No downloadable source';
          _update(entry);
          return;
        }
        url = match.url;
        entry.url = url;
      }

      if (_removed.contains(entry.id)) return;
      final dir = await _dir();
      final ext = url.split('?').first.split('.').last;
      final safeExt = ext.length <= 4 && ext.contains(RegExp(r'^[a-zA-Z0-9]+$'))
          ? ext
          : 'mp4';
      final file = File('${dir.path}/${entry.id}.$safeExt');
      final cancellation = CancelToken();
      _cancellations[entry.id] = cancellation;
      if (Uri.tryParse(url)?.scheme == 'file') {
        await File.fromUri(Uri.parse(url)).copy(file.path);
      } else {
        await Dio().download(
          url,
          file.path,
          cancelToken: cancellation,
          onReceiveProgress: (count, total) {
            if (total > 0) {
              entry.progress = count / total;
              items.value = [...items.value];
            }
          },
        );
      }
      entry.path = file.path;
      entry.progress = 1;
      entry.status = DownloadStatus.done;
      _update(entry);
    } catch (error) {
      entry.status = DownloadStatus.failed;
      entry.error = error.toString();
      _update(entry);
    }
  }
}
