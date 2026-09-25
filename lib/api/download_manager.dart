import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/models/stream.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum DownloadStatus { queued, running, done, failed, unavailable }

class DownloadEntry {
  final String id;
  final String title;
  final int tmdbId;
  final int? season;
  final int? episode;
  String? url;
  String? path;
  double progress;
  DownloadStatus status;
  String? error;

  DownloadEntry({
    required this.id,
    required this.title,
    required this.tmdbId,
    this.season,
    this.episode,
    this.url,
    this.path,
    this.progress = 0,
    this.status = DownloadStatus.queued,
    this.error,
  });

  bool get isShow => season != null && episode != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tmdbId': tmdbId,
        'season': season,
        'episode': episode,
        'url': url,
        'path': path,
        'progress': progress,
        'status': status.name,
        'error': error,
      };

  factory DownloadEntry.fromJson(Map<String, dynamic> json) {
    return DownloadEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Download',
      tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      url: json['url'] as String?,
      path: json['path'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status: DownloadStatus.values.firstWhere((value) => value.name == json['status'], orElse: () => DownloadStatus.queued),
      error: json['error'] as String?,
    );
  }
}

class DownloadManager {
  static final ValueNotifier<List<DownloadEntry>> items = ValueNotifier(const []);
  static bool _busy = false;
  static bool _loaded = false;

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
      items.value = raw.map((row) => DownloadEntry.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (_) {}
  }

  static Future<void> _persist() async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(items.value.map((e) => e.toJson()).toList()));
  }

  static bool canSave(String url) {
    final lower = url.toLowerCase();
    if (url.isEmpty) return false;
    if (lower.startsWith('magnet:')) return false;
    if (lower.contains('infohash')) return false;
    return lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('file://');
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
  }) async {
    await load();
    if (!canSave(stream.url)) {
      throw Exception('This source cannot be saved on device.');
    }
    final id = _id(tmdbId: tmdbId, season: season, episode: episode);
    final existing = [...items.value];
    final index = existing.indexWhere((item) => item.id == id);
    final entry = DownloadEntry(
      id: id,
      title: title,
      tmdbId: tmdbId,
      season: season,
      episode: episode,
      url: stream.url,
      status: DownloadStatus.queued,
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
    if (items.value.any((item) => item.id == id && item.status != DownloadStatus.failed)) return;
    items.value = [
      DownloadEntry(id: id, title: title, tmdbId: tmdbId, season: season, episode: episode),
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
      await enqueueEpisode(tmdbId: tmdbId, title: '$showName S$season:E$episode', season: season, episode: episode);
    }
  }

  static Future<void> remove(String id) async {
    final entry = items.value.where((item) => item.id == id).firstOrNull;
    if (entry?.path != null) {
      try {
        final file = File(entry!.path!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    items.value = items.value.where((item) => item.id != id).toList();
    await _persist();
  }

  static Future<void> _pump() async {
    if (_busy) return;
    _busy = true;
    try {
      while (true) {
        final queued = items.value.where((item) => item.status == DownloadStatus.queued).firstOrNull;
        if (queued == null) break;
        await _run(queued);
      }
    } finally {
      _busy = false;
    }
  }

  static void _update(DownloadEntry entry) {
    items.value = [for (final item in items.value) item.id == entry.id ? entry : item];
    _persist();
  }

  static Future<void> _run(DownloadEntry entry) async {
    entry.status = DownloadStatus.running;
    _update(entry);
    try {
      var url = entry.url;
      if (url == null || url.isEmpty) {
        final show = entry.season != null;
        final details = show ? await TMDB.tvShow(entry.tmdbId) : await TMDB.movie(entry.tmdbId);
        final imdb = (details as dynamic).imdbId as String?;
        if (imdb == null || imdb.isEmpty) {
          entry.status = DownloadStatus.unavailable;
          entry.error = 'Missing IMDb id';
          _update(entry);
          return;
        }
        final streams = await StreamApi.fetchStreams(
          imdb,
          show ? Episode(seasonNumber: entry.season!, episodeNumber: entry.episode!) : null,
        );
        final match = streams.where((stream) => !stream.external && canSave(stream.url)).firstOrNull;
        if (match == null) {
          entry.status = DownloadStatus.unavailable;
          entry.error = 'No downloadable source';
          _update(entry);
          return;
        }
        url = match.url;
        entry.url = url;
      }

      final dir = await _dir();
      final ext = url.split('?').first.split('.').last;
      final safeExt = ext.length <= 4 && ext.contains(RegExp(r'^[a-zA-Z0-9]+$')) ? ext : 'mp4';
      final file = File('${dir.path}/${entry.id}.$safeExt');
      await Dio().download(
        url,
        file.path,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            entry.progress = count / total;
            items.value = [...items.value];
          }
        },
      );
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
