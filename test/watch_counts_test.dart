import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/utils/watch_counts.dart';

void main() {
  WatchHistoryItem movie({int plays = 0, List<DateTime> dates = const [], double completion = 0}) =>
    WatchHistoryItem(tmdbId: 42, mediaType: MediaType.movie, completion: completion,
      updatedAt: DateTime(2026), plays: plays, watches: dates);
  test('movie count survives a new viewing cycle and preserves legacy totals', () {
    expect(WatchCounts.movie([movie(plays: 5, dates: [DateTime(2026)], completion: .2)], 42), 5);
    expect(WatchCounts.movie([movie(dates: [DateTime(2025), DateTime(2026)])], 42), 2);
    expect(WatchCounts.movie([movie(completion: 1)], 42), 1);
    expect(WatchCounts.movie([movie(completion: .5)], 42), 0);
    expect(WatchCounts.movie([movie(plays: 2), movie(plays: 2)], 42), 2);
  });
  test('full show viewings require every aired episode and exclude specials', () {
    final history = [WatchHistoryItem(
      tmdbId: 42, mediaType: MediaType.show, completion: 0, updatedAt: DateTime(2026),
      episodes: [
        EpisodeProgress(season: 1, episode: 1, completion: .1, plays: 3),
        EpisodeProgress(season: 1, episode: 2, completion: 1, plays: 2),
        EpisodeProgress(season: 0, episode: 1, completion: 1, plays: 8),
      ])];
    final counts = WatchCounts.episodes(history, 42);
    expect(WatchCounts.fullViewings(counts, ['1:1', '1:2']), 2);
    expect(WatchCounts.fullViewings(counts, ['1:1', '1:2', '1:3']), 0);
    expect(WatchCounts.fullViewings(counts, []), 0);
    expect(WatchCounts.episode(history, 42, 1, 1), 3);
    expect(WatchCounts.episode(history, 42, 1, 9), 0);
  });
}
