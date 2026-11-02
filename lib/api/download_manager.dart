import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:petal/api/download_network.dart';
import 'package:petal/api/resumable_download.dart';
import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/api/device_storage.dart';
import 'package:petal/models/downloads/download_storage.dart';

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
  static final wifiOnly = ValueNotifier(false);
  static final waitingForWifi = ValueNotifier(false);
  static Timer? _networkTimer;
  static bool _busy = false;

  static Future<void> setWifiOnly(bool value) async {
    await load();
    wifiOnly.value = value;
    await (await SharedPreferences.getInstance()).setBool(
      'downloads.wifiOnly',
      value,
    );
    if (value && !await DownloadNetwork.wifi()) {
      for (final token in _cancellations.values) {
        token.cancel('Waiting for Wi-Fi');
      }
    }
    _pump();
  }

  static Future<void> pause(String id) async {
    final entry = items.value.where((e) => e.id == id).firstOrNull;
    if (entry == null ||
        (entry.status != DownloadStatus.running &&
            entry.status != DownloadStatus.queued))
      return;
    entry.status = DownloadStatus.paused;
    _cancellations[id]?.cancel('Paused');
    _update(entry);
    await _jobs[id];
    await _persist();
  }

  static Future<void> resume(String id) async {
    await _jobs[id];
    final entry = items.value.where((e) => e.id == id).firstOrNull;
    if (entry == null || entry.status != DownloadStatus.paused) return;
    entry.status = DownloadStatus.queued;
    entry.error = null;
    _update(entry);
    _pump();
  }

  static Future<void> moveEarlier(String id) async {
    final list = [...items.value];
    final i = list.indexWhere((e) => e.id == id);
    final previous = list
        .take(i < 0 ? 0 : i)
        .lastWhereOrNull((e) => e.status == DownloadStatus.queued);
    if (i < 0 || previous == null) return;
    list.removeAt(i);
    list.insert(list.indexOf(previous), items.value[i]);
    items.value = list;
    await _persist();
  }

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

  static Future<void>? _loading;
  static Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load().whenComplete(() {
      _loaded = true;
    });
  }

  static Future<void> _load() async {
    try {
      wifiOnly.value =
          (await SharedPreferences.getInstance()).getBool(
            'downloads.wifiOnly',
          ) ??
          false;
    } catch (_) {}
    _networkTimer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      if (wifiOnly.value && _busy && !await DownloadNetwork.wifi()) {
        for (final token in _cancellations.values) {
          token.cancel('Waiting for Wi-Fi');
        }
      }
      if (!_busy) _pump();
    });
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
      for (final entry in items.value) {
        if (entry.status == DownloadStatus.running ||
            entry.status == DownloadStatus.queued) {
          entry.status = DownloadStatus.paused;
          entry.error = 'Download interrupted. Resume to continue.';
        } else if (entry.status == DownloadStatus.done &&
            (entry.path == null || !await File(entry.path!).exists())) {
          entry.status = DownloadStatus.failed;
          entry.error =
              'Downloaded file is missing. Retry to download it again.';
        }
      }
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

  static Future<void> setPlaybackProgress(
    String id,
    double completion, {
    String? profileKey,
    bool sync = true,
  }) async {
    final entry = items.value.where((item) => item.id == id).firstOrNull;
    if (entry == null) return;
    entry.playbackProgress = completion.clamp(0, 1);
    if (sync)
      await OfflineProgressSync.instance.record(
        profileKey: profileKey,
        mediaId: entry.tmdbId,
        season: entry.season,
        episode: entry.episode,
        completion: entry.playbackProgress,
      );
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
      return;
    } else {
      existing.add(entry);
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
      ...items.value.where((item) => item.id != id),
      DownloadEntry(
        id: id,
        title: title,
        tmdbId: tmdbId,
        season: season,
        episode: episode,
      ),
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

  static Future<void> retry(String id, {bool newSource = false}) async {
    if (_jobs.containsKey(id)) return;
    final entry = items.value.where((entry) => entry.id == id).firstOrNull;
    if (entry == null ||
        (entry.status != DownloadStatus.failed &&
            entry.status != DownloadStatus.unavailable))
      return;
    _removed.remove(id);
    if (newSource) {
      entry.url = null;
      entry.validator = null;
      if (entry.path != null && await File(entry.path!).exists())
        await File(entry.path!).delete();
    }
    entry.error = null;
    entry.progress = 0;
    entry.downloadedBytes = 0;
    entry.totalBytes = 0;
    entry.status = DownloadStatus.queued;
    _update(entry);
    await _persist();
    _pump();
  }

  static Future<DownloadStorage> storage() async {
    final dir = await _dir();
    var used = 0;
    await for (final file in dir.list()) {
      if (file is File &&
          !file.path.endsWith('index.json') &&
          !file.path.endsWith('.tmp')) {
        try {
          used += await file.length();
        } catch (_) {}
      }
    }
    var changed = false;
    for (final entry in items.value.where(
      (entry) => entry.status == DownloadStatus.done && entry.path != null,
    )) {
      try {
        final size = await File(entry.path!).length();
        if (entry.downloadedBytes != size || entry.totalBytes != size)
          changed = true;
        entry.downloadedBytes = entry.totalBytes = size;
      } catch (_) {}
    }
    if (changed) items.value = [...items.value];
    return DownloadStorage(
      usedBytes: used,
      freeBytes: await DeviceStorage.freeBytes(dir.path),
    );
  }

  static Future<void> _pump() async {
    if (_busy) return;
    _busy = true;
    try {
      while (true) {
        final queued = items.value
            .where((item) => item.status == DownloadStatus.queued)
            .firstOrNull;
        if (queued == null) {
          waitingForWifi.value = false;
          break;
        }
        final local =
            queued.url != null && Uri.tryParse(queued.url!)?.scheme == 'file';
        if (wifiOnly.value && !local && !await DownloadNetwork.wifi()) {
          waitingForWifi.value = true;
          break;
        }
        waitingForWifi.value = false;
        if (queued.status != DownloadStatus.queued ||
            _removed.contains(queued.id))
          continue;
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
    final cancellation = CancelToken();
    _cancellations[entry.id] = cancellation;
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
          if (entry.status == DownloadStatus.paused ||
              _removed.contains(entry.id))
            return;
          if (cancellation.isCancelled) throw cancellation.cancelError!;
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
          if (entry.status == DownloadStatus.paused ||
              _removed.contains(entry.id))
            return;
          if (cancellation.isCancelled) throw cancellation.cancelError!;
          entry.status = DownloadStatus.unavailable;
          entry.error = 'No downloadable source';
          _update(entry);
          return;
        }
        url = match.url;
        entry.url = url;
      }

      if (_removed.contains(entry.id) || entry.status == DownloadStatus.paused)
        return;
      if (cancellation.isCancelled) throw cancellation.cancelError!;
      final dir = await _dir();
      final ext = url.split('?').first.split('.').last;
      final safeExt = ext.length <= 4 && ext.contains(RegExp(r'^[a-zA-Z0-9]+$'))
          ? ext
          : 'mp4';
      final file = File('${dir.path}/${entry.id}.$safeExt');
      entry.path = file.path;
      await _persist();
      if (Uri.tryParse(url)?.scheme == 'file') {
        await File.fromUri(Uri.parse(url)).copy(file.path);
      } else {
        await ResumableDownload.run(
          dio: Dio(),
          url: url,
          file: file,
          cancelToken: cancellation,
          previousValidator: entry.validator,
          validator: (value) {
            entry.validator = value;
            _persist();
          },
          progress: (count, total) {
            entry.downloadedBytes = count;
            entry.totalBytes = total > 0 ? total : 0;
            if (total > 0) entry.progress = count / total;
            items.value = [...items.value];
          },
        );
      }
      if (entry.status == DownloadStatus.paused || _removed.contains(entry.id))
        return;
      if (cancellation.isCancelled) throw cancellation.cancelError!;
      entry.path = file.path;
      entry.downloadedBytes = entry.totalBytes = await file.length();
      entry.progress = 1;
      entry.status = DownloadStatus.done;
      _update(entry);
    } catch (error) {
      if (_removed.contains(entry.id)) return;
      if (entry.status == DownloadStatus.paused) {
        _update(entry);
        return;
      }
      if (error is DioException && CancelToken.isCancel(error)) {
        entry.status = DownloadStatus.queued;
        _update(entry);
        return;
      }
      entry.status = DownloadStatus.failed;
      entry.error = error.toString();
      _update(entry);
    }
  }
}
