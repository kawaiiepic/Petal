import 'dart:async';

import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_datasets.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/models/watch_session.dart';
import 'package:petal/utils/frame_safe_value_notifier.dart';

class BackendCache {
  static final continueWatching =
      FrameSafeValueNotifier<List<ContinueWatchingItem>>([]);
  static final watchHistory = FrameSafeValueNotifier<List<WatchHistoryItem>>(
    [],
  );
  static final sessions = FrameSafeValueNotifier<List<WatchSession>>([]);
  static final _nextUp = BackendDatasets.create<List<ContinueWatchingItem>>(
    name: 'next-up', versionField: 'progress_version',
    maxAge: const Duration(minutes: 5),
    encode: (items) => items.map(_nextUpJson).toList(),
    decode: (raw) => (raw as List).map((r) =>
      ContinueWatchingItem.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
  );
  static final _history = BackendDatasets.create<List<WatchHistoryItem>>(
    name: 'history', versionField: 'progress_version',
    encode: (items) => items.map(_historyJson).toList(),
    decode: (raw) => (raw as List).map((r) =>
      WatchHistoryItem.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
  );
  static final _optimisticShows = <String, Map<int, WatchHistoryItem>>{};

  static List<WatchHistoryItem> _withOptimistic(
      String profile, List<WatchHistoryItem> rows) {
    final overlays = _optimisticShows[profile];
    if (overlays == null || overlays.isEmpty) return rows;
    return [
      ...rows.where((h) => h.mediaType.name != 'show' || !overlays.containsKey(h.tmdbId)),
      ...overlays.values,
    ];
  }

  static void optimisticShow(String profile, WatchHistoryItem row) {
    (_optimisticShows[profile] ??= {})[row.tmdbId] = row;
    if (profile == BackendApi.profileCacheKey) {
      watchHistory.value = _withOptimistic(profile, watchHistory.value);
    }
  }

  static void finishOptimisticShow(String profile, int id,
      {WatchHistoryItem? restore, bool rollback = false}) {
    _optimisticShows[profile]?.remove(id);
    if (_optimisticShows[profile]?.isEmpty == true) _optimisticShows.remove(profile);
    if (rollback && profile == BackendApi.profileCacheKey) {
      watchHistory.value = [
        ...watchHistory.value.where((h) => h.mediaType.name != 'show' || h.tmdbId != id),
        if (restore != null) restore,
      ];
    }
  }

  static String? _profileKey;
  static int _revision = 0;

  static void onAuthChanged() {
    _syncProfile();
    unawaited(fetchWatchHistory().catchError((Object _) {}));
    unawaited(fetchContinueWatching().catchError((Object _) {}));
  }

  static String? _syncProfile() {
    final key = BackendApi.profileCacheKey;
    if (key != _profileKey) {
      _profileKey = key;
      _revision++;
      continueWatching.value = [];
      watchHistory.value = [];
      sessions.value = [];
    }
    return key;
  }

  static void invalidateProgress({String? profileKey}) {
    _syncProfile();
    final key = profileKey ?? _syncProfile();
    if (key == null) return;
    _nextUp.invalidate(key);
    _history.invalidate(key);
    if (key == BackendApi.profileCacheKey) _revision++;
  }

  static Future<void> fetchContinueWatching({bool force = false}) async {
    final key = _syncProfile();
    if (key == null) return;
    final revision = _revision;
    // The backend selects aired next episodes and resumes saved partial progress.
    // Card artwork and metadata load independently after this list is published.
    final items = await _nextUp.get(
      scope: key, profileId: BackendApi.authState.selectedProfile!.id,
      load: BackendApi.continueWatching, force: force,
      onUpdated: (items) {
        if (revision == _revision && key == BackendApi.profileCacheKey) {
          continueWatching.value = items;
        }
      },
    );
    if (revision == _revision &&
        key == BackendApi.profileCacheKey &&
        !identical(continueWatching.value, items)) {
      continueWatching.value = items;
    }
  }

  static Future<void> fetchWatchHistory({bool force = false}) async {
    final key = _syncProfile();
    if (key == null) return;
    final revision = _revision;
    final items = await _history.get(
      scope: key, profileId: BackendApi.authState.selectedProfile!.id,
      load: BackendApi.watchHistory, force: force,
      onUpdated: (items) {
        if (revision == _revision && key == BackendApi.profileCacheKey) {
          watchHistory.value = _withOptimistic(key, items);
        }
      },
    );
    if (revision == _revision &&
        key == BackendApi.profileCacheKey &&
        !identical(watchHistory.value, items)) {
      watchHistory.value = items;
    }
  }
}

int? _unix(DateTime? date) => date == null ? null : date.toUtc().millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> _historyJson(WatchHistoryItem item) => {
  'tmdb_id': item.tmdbId, 'media_type': item.mediaType.name,
  'completion': item.completion, 'updated_at': _unix(item.updatedAt),
  'last_watched': _unix(item.lastWatched), 'watched_at': _unix(item.watchedAt),
  'plays': item.plays, 'watches': item.watches.map(_unix).toList(),
  'episodes': item.episodes.map((e) => {
    'season': e.season, 'episode': e.episode, 'completion': e.completion,
    'plays': e.plays, 'watched_at': _unix(e.watchedAt),
    'watches': e.watches.map(_unix).toList(),
  }).toList(),
};

Map<String, dynamic> _nextUpJson(ContinueWatchingItem item) => {
  'tmdb_id': item.tmdbId, 'media_type': item is MovieItem ? 'movie' : 'episode',
  'last_watched': _unix(item.lastWatched),
  if (item is MovieItem) 'completion': item.completion,
  if (item is ShowItem) ...{
    'next_episode': item.nextEpisode == null ? null : {
      'season': item.nextEpisode!.season, 'episode': item.nextEpisode!.episode,
      'completion': item.nextEpisode!.completion,
    },
    'seasons': item.seasons.map((s) => {
      'number': s.number, 'episodes': s.episodes.map((e) => {
        'episode': e.episode, 'completion': e.completion,
      }).toList(),
    }).toList(),
  },
};
