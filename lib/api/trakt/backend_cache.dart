import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/session.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class BackendCache {
  static var continueWatching = ValueChangeNotifier<List<ContinueWatchingItem>>([]);
  static var watchHistory = ValueChangeNotifier<List<WatchHistoryItem>>([]);
  static var sessions = ValueChangeNotifier<List<WatchSession>>([]);

  static Future<void> fetchContinueWatching() async {
    final items = await BackendApi.continueWatching();

    final filtered = <ContinueWatchingItem>[];

    for (final item in items) {
      if (item is ShowItem && item.nextEpisode != null) {
        final episode = await TMDB.tvEpisode(item.tmdbId, item.nextEpisode!.season, item.nextEpisode!.episode);
        final airDate = episode.airDate; // adjust to your actual field name
        if (airDate == null || airDate.isAfter(DateTime.now())) {
          continue; // not released yet — skip it
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
