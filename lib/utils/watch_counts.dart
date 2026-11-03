import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

/// Completion describes this viewing cycle; plays and dates describe all cycles.
abstract final class WatchCounts {
  static int _count(int plays, int dates, double completion) {
    var count = plays > dates ? plays : dates;
    if (completion >= 1 && count < 1) count = 1;
    return count < 0 ? 0 : count;
  }

  static int movie(List<WatchHistoryItem> history, int id) {
    var count = 0;
    for (final row in history.where((h) => h.tmdbId == id && h.mediaType == MediaType.movie)) {
      final value = _count(row.plays, row.watches.length, row.completion);
      if (value > count) count = value;
    }
    return count;
  }

  static Map<String, int> episodes(List<WatchHistoryItem> history, int id) {
    final result = <String, int>{};
    for (final row in history.where((h) => h.tmdbId == id && h.mediaType == MediaType.show)) {
      for (final ep in row.episodes) {
        final key = '${ep.season}:${ep.episode}';
        final count = _count(ep.plays, ep.watches.length, ep.completion);
        if (count > (result[key] ?? 0)) result[key] = count;
      }
    }
    return result;
  }

  static int episode(List<WatchHistoryItem> history, int id, int season, int episode) =>
      episodes(history, id)['$season:$episode'] ?? 0;

  static int fullViewings(Map<String, int> counts, Iterable<String> aired) {
    final keys = aired.toSet();
    if (keys.isEmpty) return 0;
    int? minimum;
    for (final key in keys) {
      final value = counts[key] ?? 0;
      if (minimum == null || value < minimum) minimum = value;
    }
    return minimum ?? 0;
  }
}
