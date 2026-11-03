import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:flutter/foundation.dart';

/// Playback only records locally. Uploads run separately and are opt-in.
class OfflineProgressSync extends ChangeNotifier {
  static final instance = OfflineProgressSync();
  bool enabled = false;
  final Map<String, Map<String, dynamic>> _queue = {};
  Future<void>? _loading, _syncing;
  Future<void> _writes = Future.value();
  bool _loaded = false;
  int _suspended = 0, _revision = 0;
  String? lastError;
  Timer? _timer;
  int get pending => _queue.length;
  void suspend() => _suspended++;
  void resume() {
    if (_suspended > 0) _suspended--;
  }

  void start({required bool Function() online}) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (online()) sync();
    });
  }

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        enabled = prefs.getBool('offline.sync.enabled') ?? false;
        try {
          final rows = jsonDecode(
            prefs.getString('offline.sync.queue') ?? '{}',
          ) as Map<String, dynamic>;
          for (final row in rows.entries) {
            _queue[row.key] = Map<String, dynamic>.from(row.value as Map);
          }
        } catch (_) {}
      } catch (_) {
        enabled = false;
      }
      _loaded = true;
      notifyListeners();
    }();
  }

  Future<void> setEnabled(bool value) async {
    await load();
    enabled = value;
    if (!value) {
      _queue.clear();
      lastError = null;
    }
    await (await SharedPreferences.getInstance()).setBool(
      'offline.sync.enabled',
      value,
    );
    await _persist();
    notifyListeners();
    if (value) await sync();
  }

  Future<void> record({
    required String? profileKey,
    required int mediaId,
    int? season,
    int? episode,
    required double completion,
  }) async {
    await load();
    if (!enabled || profileKey == null) return;
    final key = '$profileKey|$mediaId|$season|$episode';
    final previous = (_queue[key]?['completion'] as num?)?.toDouble() ?? 0;
    final value = WatchProgress.storedCompletion(completion);
    _queue[key] = {
      'profile': profileKey,
      'media': mediaId,
      'season': season,
      'episode': episode,
      'completion': value > previous ? value : previous,
      'at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'revision': ++_revision,
    };
    await _persist();
    notifyListeners();
  }

  bool hasPending({required String profileKey, required int mediaId, int? season, int? episode}) =>
      _queue.containsKey('$profileKey|$mediaId|$season|$episode');

  Future<void> settle() async {
    await _syncing;
  }

  Future<void> discard({
    required String profileKey,
    required int mediaId,
    int? season,
    int? episode,
  }) async {
    await load();
    _queue.remove('$profileKey|$mediaId|$season|$episode');
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() {
    final raw = jsonEncode(_queue);
    return _writes = _writes.catchError((Object _) {}).then((_) async {
      await (await SharedPreferences.getInstance()).setString(
        'offline.sync.queue',
        raw,
      );
    });
  }

  Future<void> sync() {
    if (_syncing != null) return _syncing!;
    return _syncing = _upload().whenComplete(() => _syncing = null);
  }

  Future<void> _upload() async {
    await load();
    final profile = BackendApi.profileCacheKey;
    if (!enabled ||
        _suspended > 0 ||
        profile == null ||
        _queue.isEmpty ||
        !_queue.values.any((row) => row['profile'] == profile))
      return;
    lastError = null;
    try {
      await BackendCache.fetchWatchHistory(force: true);
      for (final entry in [..._queue.entries]) {
        if (!enabled || _suspended > 0 || BackendApi.profileCacheKey != profile)
          break;
        final row = entry.value;
        if (row['profile'] != profile) continue;
        final type = row['season'] == null ? MediaType.movie : MediaType.show;
        final local = (row['completion'] as num).toDouble();
        final remote =
            WatchProgress.playbackCompletion(
              tmdbId: row['media'] as int,
              type: type,
              season: row['season'] as int?,
              episode: row['episode'] as int?,
              history: BackendCache.watchHistory.value,
              nextUp: const [],
            ) ??
            0;
        // Never move remote progress backwards when another device watched more.
        if (local > remote)
          await BackendApi.setProgress(
            row['media'] as int,
            type,
            local,
            season: row['season'] as int?,
            episode: row['episode'] as int?,
            watchedAt: DateTime.fromMillisecondsSinceEpoch(
              row['at'] as int,
              isUtc: true,
            ),
            refresh: false,
          );
        if (BackendApi.profileCacheKey == profile &&
            identical(_queue[entry.key], row))
          _queue.remove(entry.key);
        await _persist();
      }
      if (BackendApi.profileCacheKey == profile)
        await Future.wait([
          BackendCache.fetchWatchHistory(force: true),
          BackendCache.fetchContinueWatching(force: true),
        ]);
    } catch (_) {
      lastError = 'Sync failed. Progress is saved on this device; try again when connected.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
