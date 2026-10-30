import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/models/watch_session.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class BackendCache {
  static var continueWatching = ValueChangeNotifier<List<ContinueWatchingItem>>(
    [],
  );
  static var watchHistory = ValueChangeNotifier<List<WatchHistoryItem>>([]);
  static var sessions = ValueChangeNotifier<List<WatchSession>>([]);
  static Future<void>? _continueWatchingInFlight;

  static Future<void> fetchContinueWatching() {
    return _continueWatchingInFlight ??= _fetchContinueWatching().whenComplete(
      () {
        _continueWatchingInFlight = null;
      },
    );
  }

  static Future<void> _fetchContinueWatching() async {
    final items = await BackendApi.continueWatching();

    final filtered = <ContinueWatchingItem>[];

    for (final item in items) {
      if (item is ShowItem && item.nextEpisode != null) {
        try {
          final episode = await TMDB.tvEpisode(
            item.tmdbId,
            item.nextEpisode!.season,
            item.nextEpisode!.episode,
          );
          final airDate = episode.airDate;
          if (airDate == null || airDate.isAfter(DateTime.now())) {
            continue;
          }
        } catch (_) {
          // Keep the item if TMDB lookup fails so the shelf can still render.
        }
      }
      filtered.add(item);
    }

    continueWatching.value = filtered;
  }

  static Future<void> fetchWatchHistory() async {
    final history = await BackendApi.watchHistory();
    watchHistory.value = history;
  }
}
