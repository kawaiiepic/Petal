import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/utils/watch_counts.dart';

void checkWatchCounts() {
  WatchHistoryItem movie({int plays = 0, List<DateTime> dates = const [], double completion = 0}) =>
    WatchHistoryItem(tmdbId: 42, mediaType: MediaType.movie, completion: completion,
      updatedAt: DateTime(2026), plays: plays, watches: dates);
  {
    assert((WatchCounts.movie([movie(plays: 5, dates: [DateTime(2026)], completion: .2)], 42)) == (5));
    assert((WatchCounts.movie([movie(dates: [DateTime(2025), DateTime(2026)])], 42)) == (2));
    assert((WatchCounts.movie([movie(completion: 1)], 42)) == (1));
    assert((WatchCounts.movie([movie(completion: .5)], 42)) == (0));
    assert((WatchCounts.movie([movie(plays: 2), movie(plays: 2)], 42)) == (2));
  }
  {
    final history = [WatchHistoryItem(
      tmdbId: 42, mediaType: MediaType.show, completion: 0, updatedAt: DateTime(2026),
      episodes: [
        EpisodeProgress(season: 1, episode: 1, completion: .1, plays: 3),
        EpisodeProgress(season: 1, episode: 2, completion: 1, plays: 2),
        EpisodeProgress(season: 0, episode: 1, completion: 1, plays: 8),
      ])];
    final counts = WatchCounts.episodes(history, 42);
    assert((WatchCounts.fullViewings(counts, ['1:1', '1:2'])) == (2));
    assert((WatchCounts.fullViewings(counts, ['1:1', '1:2', '1:3'])) == (0));
    assert((WatchCounts.fullViewings(counts, [])) == (0));
    assert((WatchCounts.episode(history, 42, 1, 1)) == (3));
    assert((WatchCounts.episode(history, 42, 1, 9)) == (0));
  }
}

void main() {
  checkWatchCounts();
  print("Watch count checks passed");
}
