import 'package:petal/api/retryable_write.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/models/media_type.dart';

/// Manual edits use server-side snapshots; background playback keeps PUT state.
abstract final class HistoryActions {
  static final canUndo = ValueNotifier(false);
  static Future<void> Function()? _undo;
  static String? _profile;
  static bool _busy = false;

  static Future<void> setProgress(int id, MediaType type, double completion,
      {int? season, int? episode, bool refresh = true}) =>
      _edit(id, type, completion == 0 ? 'reset' : 'set',
          season: season, episode: episode, completion: completion, refresh: refresh);

  static Future<void> remove(int id, MediaType type,
      {int? season, int? episode}) =>
      _edit(id, type, 'delete', season: season, episode: episode);

  static Future<void> deleteWatch(int id, MediaType type, int index, DateTime at,
      {int? season, int? episode}) =>
      _edit(id, type, 'delete_watch', season: season, episode: episode,
          index: index, at: at);

  static void _checkProfile(String profile) {
    if (BackendApi.profileCacheKey != profile) throw StateError('Profile changed.');
  }

  static Future<void> _edit(int id, MediaType type, String action, {
    int? season, int? episode, double? completion, int? index, DateTime? at,
    bool refresh = true,
  }) async {
    if (_busy) throw StateError('A history update is already in progress.');
    final profile = BackendApi.profileCacheKey;
    final profileId = BackendApi.authState.selectedProfile?.id;
    if (profile == null || profileId == null) throw StateError('Select a profile first.');
    _busy = true;
    OfflineProgressSync.instance.suspend();
    try {
      await OfflineProgressSync.instance.settle();
      _checkProfile(profile);
      final url = '${Api.ServerUrl}/track/history/$profileId/${type.toBackendSafe}/$id';
      final target = <String, dynamic>{
        if (season != null) 'season': season,
        if (episode != null) 'episode': episode,
      };
      final download = DownloadManager.find(tmdbId: id, season: season, episode: episode);
      final localProgress = download?.playbackProgress;
      double? editedLocalProgress;
      final response = await retryableWrite((options) => BackendApi.dio.post('$url/edit', options: options, data: {
        ...target, 'action': action,
        if (completion != null) 'completion': completion,
        if (index != null) 'watch_index': index,
        if (at != null) 'watched_at': at.toUtc().millisecondsSinceEpoch ~/ 1000,
      }));
      final editId = response.data['result']['edit_id'] as String;
      _profile = profile;
      final undoKey = newRequestKey();
      _undo = () async {
        _checkProfile(profile);
        final currentDownload = DownloadManager.find(tmdbId: id, season: season, episode: episode);
        if (OfflineProgressSync.instance.hasPending(profileKey: profile, mediaId: id, season: season, episode: episode) ||
            (currentDownload != null && editedLocalProgress != null &&
              (currentDownload.playbackProgress - editedLocalProgress!).abs() > .0001)) {
          throw StateError('New offline progress exists. Undo would overwrite it.');
        }
        await retryableWrite((options) => BackendApi.dio.post(
          '${Api.ServerUrl}/track/history/$profileId/undo/$editId', options: options), requestKey: undoKey);
        _checkProfile(profile);
        BackendCache.invalidateProgress(profileKey: profile);
        if (download != null && localProgress != null) {
          await DownloadManager.setPlaybackProgress(download.id, localProgress, sync: false);
        }
      };
      canUndo.value = true;
      await OfflineProgressSync.instance.discard(
        profileKey: profile, mediaId: id, season: season, episode: episode);
      _checkProfile(profile);
      BackendCache.invalidateProgress(profileKey: profile);
      if (download != null) {
        final state = response.data['result']['state'] as Map?;
        double saved = 0;
        if (state != null && type == MediaType.movie) {
          saved = (state['completion'] as num?)?.toDouble() ?? 0;
        } else if (state != null) {
          final raw = state['episodes'];
          final episodes = raw is String ? jsonDecode(raw) as List : raw as List;
          for (final value in episodes) {
            if (value['season'] == season && value['episode'] == episode) {
              saved = (value['completion'] as num).toDouble();
              break;
            }
          }
        }
        editedLocalProgress = saved;
        await DownloadManager.setPlaybackProgress(download.id, saved, sync: false);
      }
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

  static String errorMessage(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is DioException) {
      if (error.response?.statusCode == 409 && error.response?.headers.value('Retry-After') != null) {
        return 'Request outcome is pending. Refresh history before another edit.';
      }
      if (error.response?.statusCode == 409) return 'History changed or Undo expired. Refresh before editing again.';
      if (error.response?.statusCode == 404) return 'History editing is unavailable. The updated backend must be deployed first.';
    }
    return 'Could not update history. Please try again.';
  }

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
