import 'package:petal/utils/collection_progress.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/models/watch_history/watch_stats_snapshot.dart';
import 'package:petal/utils/watch_progress.dart';

WatchHistoryItem history(List<double> completions) =>
    WatchHistoryItem.fromJson({
      'tmdb_id': 42,
      'media_type': 'show',
      'updated_at': 1700000000,
      'episodes': [
        for (var i = 0; i < completions.length; i++)
          {'season': 1, 'episode': i + 1, 'completion': completions[i]},
      ],
    });

void main() {
  test('collection excludes fully watched shows even with partial specials', () {
    final item = WatchHistoryItem.fromJson({
      'tmdb_id': 42, 'media_type': 'show', 'updated_at': 1700000000,
      'episodes': [
        {'season': 1, 'episode': 1, 'completion': 1},
        {'season': 1, 'episode': 2, 'completion': .9},
        {'season': 0, 'episode': 1, 'completion': .4},
      ],
    });
    expect(isWatching(item, tmdbEpisodeCount: 2), isFalse);
    expect(isFinished(item, tmdbEpisodeCount: 2), isTrue);
    expect(isWatching(item, tmdbEpisodeCount: 3), isTrue);
    expect(isWatching(item), isFalse);
  });

  test('collection uses last aired episode instead of announced season total', () {
    final show = TmdbShow.fromJson({
      'id': 42, 'number_of_episodes': 12,
      'last_episode_to_air': {'id': 1, 'season_number': 1,
        'episode_number': 2, 'show_id': 42},
      'seasons': [{'id': 1, 'season_number': 1, 'episode_count': 12}],
    });
    final entry = CollectionHistoryEntry(item: history([1, 1]), metadata: show);
    expect(entry.episodeCount, 2);
    expect(isFinished(entry.item, tmdbEpisodeCount: entry.episodeCount), isTrue);
    expect(isWatching(entry.item, tmdbEpisodeCount: entry.episodeCount), isFalse);
  });

  test(
    '90% is the exact watched boundary; partial progress remains resumable',
    () {
      expect(WatchProgress.storedCompletion(0.899), 0.899);
      expect(WatchProgress.isWatched(0.899), isFalse);
      expect(WatchProgress.storedCompletion(0.9), 1);
      expect(WatchProgress.storedCompletion(0.99), 1);
      expect(WatchProgress.isPartial(0.2), isTrue);
      expect(WatchProgress.isPartial(0.9), isFalse);
    },
  );

  test('stats do not count merely started episodes as watched', () {
    expect(
      WatchStatsSnapshot.fromHistory([
        history([0.01, 0.5, 0.899]),
      ]).episodes,
      0,
    );
    final stats = WatchStatsSnapshot.fromHistory([
      history([0.01, 0.9, 1]),
    ]);
    expect(stats.shows, 1);
    expect(stats.episodes, 2);
  });

  test('badge works for partial and between-episode progress in any shelf', () {
    bool active(List<double> completions, {int? total}) =>
        WatchProgress.titleInProgress(
          tmdbId: 42,
          type: MediaType.show,
          history: [history(completions)],
          nextUp: [],
          totalEpisodes: total,
        );
    expect(active([0.2]), isTrue);
    expect(active([1], total: 3), isTrue);
    expect(active([1, 1, 1], total: 3), isFalse);
    expect(active([0], total: 3), isFalse);
    expect(
      WatchProgress.titleInProgress(
        tmdbId: 42,
        type: MediaType.show,
        history: [
          history([1]),
        ],
        nextUp: [
          ContinueWatchingItem.fromJson({
            'tmdb_id': 42,
            'media_type': 'show',
            'next_episode': {'season': 1, 'episode': 2},
            'seasons': [],
          }),
        ],
      ),
      isTrue,
    );
  });
}
