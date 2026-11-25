import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/history_timeline.dart';

void main() {
  test('episodes and rewatches use their own watch dates', () {
    final first = DateTime(2026, 11, 20);
    final second = DateTime(2026, 11, 21);
    final third = DateTime(2026, 11, 22);
    final plays = historyTimeline([
      WatchHistoryItem(
        tmdbId: 1, mediaType: MediaType.show, completion: 1,
        updatedAt: DateTime(2026, 11, 24),
        episodes: [
          EpisodeProgress(season: 1, episode: 1, completion: 1,
            watches: [first, third]),
          EpisodeProgress(season: 1, episode: 2, completion: 1,
            watchedAt: second),
          EpisodeProgress(season: 1, episode: 3, completion: .5),
        ],
      ),
    ]);
    expect(plays.map((p) => p.date).toList(), [third, second, first, null]);
    expect(plays.map((p) => p.episode!.episode).toList(), [1, 2, 1, 3]);
  });
}
