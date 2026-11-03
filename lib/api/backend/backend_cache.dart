import 'dart:async';

import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/cache/async_cache.dart';
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
  static final _nextUp = AsyncCache<String, List<ContinueWatchingItem>>(
    ttl: const Duration(minutes: 1),
  );
  static final _history = AsyncCache<String, List<WatchHistoryItem>>(
    ttl: const Duration(minutes: 1),
  );
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
      _nextUp.clear();
      _history.clear();
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
      key,
      BackendApi.continueWatching,
      force: force,
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
      key,
      BackendApi.watchHistory,
      force: force,
    );
    if (revision == _revision &&
        key == BackendApi.profileCacheKey &&
        !identical(watchHistory.value, items)) {
      watchHistory.value = items;
    }
  }
}
