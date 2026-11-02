import 'package:petal/api/download_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/watch_progress.dart';

/// Undo restores progress only: the backend does not expose watch-event deletion.
abstract final class HistoryActions {
  static final canUndo = ValueNotifier(false);
  static Future<void> Function()? _undo;
  static String? _profile;
  static bool _busy = false;

  static Future<void> setProgress(
    int id,
    MediaType type,
    double completion, {
    int? season,
    int? episode,
    bool refresh = true,
  }) async {
    if (_busy) throw StateError('A history update is already in progress.');
    final profile = BackendApi.profileCacheKey;
    if (profile == null) throw StateError('Select a profile first.');
    _busy = true;
    OfflineProgressSync.instance.suspend();
    try {
      await OfflineProgressSync.instance.settle();
      await BackendCache.fetchWatchHistory(force: true);
      if (BackendApi.profileCacheKey != profile)
        throw StateError('Profile changed.');
      final previous =
          WatchProgress.playbackCompletion(
            tmdbId: id,
            type: type,
            season: season,
            episode: episode,
            history: BackendCache.watchHistory.value,
            nextUp: const [],
          ) ??
          0;
      final download = DownloadManager.find(
        tmdbId: id,
        season: season,
        episode: episode,
      );
      final localProgress = download?.playbackProgress;
      await BackendApi.setProgress(
        id,
        type,
        completion,
        season: season,
        episode: episode,
        refresh: false,
      );
      await OfflineProgressSync.instance.discard(
        profileKey: profile,
        mediaId: id,
        season: season,
        episode: episode,
      );
      if (download != null)
        await DownloadManager.setPlaybackProgress(
          download.id,
          completion,
          sync: false,
        );
      _profile = profile;
      _undo = () async {
        await BackendCache.fetchWatchHistory(force: true);
        if (BackendApi.profileCacheKey != profile)
          throw StateError('Profile changed.');
        final current =
            WatchProgress.playbackCompletion(
              tmdbId: id,
              type: type,
              season: season,
              episode: episode,
              history: BackendCache.watchHistory.value,
              nextUp: const [],
            ) ??
            0;
        if ((current - completion).abs() > .0001)
          throw StateError(
            'Progress changed since the edit. Refresh history before editing again.',
          );
        await BackendApi.setProgress(
          id,
          type,
          previous,
          season: season,
          episode: episode,
          refresh: false,
        );

        if (download != null && localProgress != null)
          await DownloadManager.setPlaybackProgress(
            download.id,
            localProgress,
            sync: false,
          );
      };
      canUndo.value = true;
      if (refresh) await _refresh();
    } finally {
      OfflineProgressSync.instance.resume();
      _busy = false;
    }
  }

  static Future<void> _refresh() => Future.wait([
    BackendCache.fetchWatchHistory(force: true),
    BackendCache.fetchContinueWatching(force: true),
  ]);

  static Future<void> undo() async {
    if (_busy || _undo == null) return;
    if (_profile != BackendApi.profileCacheKey) {
      _undo = null;
      canUndo.value = false;
      throw StateError('This undo belongs to another profile.');
    }
    _busy = true;
    OfflineProgressSync.instance.suspend();
    try {
      await OfflineProgressSync.instance.settle();
      if (_profile != BackendApi.profileCacheKey)
        throw StateError('Profile changed.');
      await _undo!();
      _undo = null;
      canUndo.value = false;
      await _refresh();
    } finally {
      OfflineProgressSync.instance.resume();
      _busy = false;
    }
  }
}
