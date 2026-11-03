import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/next_episode.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/on_deck_selection.dart';

ShowItem show(int id, {double completion = 0, DateTime? lastWatched}) =>
    ShowItem(
      tmdbId: id,
      lastWatched: lastWatched,
      nextEpisode: NextEpisode(season: 1, episode: 2, completion: completion),
      seasons: [],
    );
LibraryTitle saved(int id, {MediaType type = MediaType.show}) =>
    LibraryTitle(tmdbId: id, type: type, watchlisted: true);
DateTime date(int day) => DateTime.utc(2026, 10, day);

void main() {
  test('resumes, movies and untouched next episodes mix by last watched', () {
    final entries = selectOnDeck(
      progress: [
        show(1, lastWatched: date(1)),
        MovieItem(tmdbId: 2, completion: .7, lastWatched: date(3)),
        show(3, completion: .2, lastWatched: date(2)),
      ],
      history: [],
      watchlist: [],
    );
    expect(entries.map((entry) => entry.tmdbId), [2, 3, 1]);
  });

  test('a full shelf reserves one new watchlist title and stays within 12', () {
    final entries = selectOnDeck(
      progress: [for (var i = 1; i <= 20; i++) show(i, lastWatched: date(i))],
      history: [],
      watchlist: [saved(100)],
    );
    expect(entries.length, 12);
    expect(entries.map((entry) => entry.tmdbId), [
      ...List.generate(11, (i) => 20 - i),
      100,
    ]);
    expect(entries.last.watchlistTitle!.tmdbId, 100);
  });

  test(
    'sparse activity fills remaining spaces from watchlist without duplicates',
    () {
      final entries = selectOnDeck(
        progress: [show(1)],
        history: [],
        watchlist: [saved(1), saved(2), saved(2), saved(3)],
      );
      expect(entries.map((entry) => entry.tmdbId), [1, 2, 3]);
      expect(entries.first.progress, isNotNull);
      expect(entries.skip(1).every((entry) => entry.progress == null), isTrue);
    },
  );

  test('an overlapping watchlist title outside the cutoff is reserved with resume intact', () {
    final entries = selectOnDeck(
      progress: [for (var i = 1; i <= 15; i++) show(i, lastWatched: date(i))],
      history: [],
      watchlist: [saved(1)],
    );
    expect(entries.length, 12);
    expect(entries.where((entry) => entry.tmdbId == 1).length, 1);
    expect(entries.last.progress, isNotNull);
    expect(entries.last.watchlistTitle, isNotNull);
  });

  test(
    'fresh watchlist suggestion remains even if an active title is also saved',
    () {
      final entries = selectOnDeck(
        progress: [for (var i = 1; i <= 15; i++) show(i, lastWatched: date(i))],
        history: [],
        watchlist: [saved(15), saved(100)],
      );
      expect(entries.map((entry) => entry.tmdbId), containsAll([15, 100]));
      expect(entries.length, 12);
    },
  );

  test(
    'missing dates keep active playback ahead of new watchlist suggestions',
    () {
      final entries = selectOnDeck(
        progress: [show(42)],
        history: [],
        watchlist: [saved(1, type: MediaType.movie)],
      );
      expect(entries.first.progress, isNotNull);
      expect(entries.last.watchlistTitle, isNotNull);
    },
  );

  test(
    'no history still allows watchlist, and empty input hides the shelf',
    () {
      expect(
        selectOnDeck(
          progress: [],
          history: [],
          watchlist: [saved(1)],
        ).single.tmdbId,
        1,
      );
      expect(selectOnDeck(progress: [], history: [], watchlist: []), isEmpty);
      expect(
        selectOnDeck(
          progress: [show(1)],
          history: [],
          watchlist: [saved(2)],
          limit: 1,
        ).single.tmdbId,
        2,
      );
      expect(
        selectOnDeck(
          progress: [],
          history: [],
          watchlist: [saved(1)],
          limit: 0,
        ),
        isEmpty,
      );
    },
  );

  test('completed progress is omitted and movie/show IDs do not collide', () {
    final entries = selectOnDeck(
      progress: [
        show(1, completion: .9),
        MovieItem(tmdbId: 2, completion: .9),
        MovieItem(tmdbId: 3, completion: 0),
        show(4),
        show(4),
      ],
      history: [],
      watchlist: [saved(4, type: MediaType.movie)],
    );
    expect(entries.map((entry) => entry.key).toSet(), {'show:4', 'movie:4'});
  });

  test('explicit last_watched takes precedence over metadata updated_at', () {
    final entries = selectOnDeck(
      progress: [show(1), show(2)],
      history: [
        WatchHistoryItem(
          tmdbId: 1,
          mediaType: MediaType.show,
          completion: 0,
          updatedAt: date(30),
          lastWatched: date(1),
        ),
        WatchHistoryItem(
          tmdbId: 2,
          mediaType: MediaType.show,
          completion: 0,
          updatedAt: date(2),
          watchedAt: date(2),
        ),
      ],
      watchlist: [],
    );
    expect(entries.map((entry) => entry.tmdbId), [2, 1]);
  });

  test('old payloads fall back to latest history activity and inputs stay untouched', () {
    final progress = [show(1), show(2)];
    final entries = selectOnDeck(
      progress: progress,
      history: [
        WatchHistoryItem(
          tmdbId: 1,
          mediaType: MediaType.show,
          completion: 0,
          updatedAt: date(1),
          watches: [date(3), date(2)],
        ),
        WatchHistoryItem(
          tmdbId: 2,
          mediaType: MediaType.show,
          completion: 0,
          updatedAt: date(2),
        ),
      ],
      watchlist: [],
    );
    expect(entries.map((entry) => entry.tmdbId), [1, 2]);
    expect(progress.map((entry) => entry.tmdbId), [1, 2]);
  });

  test('last_watched decodes seconds, milliseconds and ISO dates', () {
    final expected = date(4);
    for (final raw in [
      expected.millisecondsSinceEpoch ~/ 1000,
      expected.millisecondsSinceEpoch,
      expected.toIso8601String(),
    ]) {
      final item = ContinueWatchingItem.fromJson({
        'tmdb_id': 1,
        'media_type': 'movie',
        'completion': .2,
        'last_watched': raw,
      });
      expect(item.lastWatched, expected);
      final history = WatchHistoryItem.fromJson({
        'tmdb_id': 1,
        'media_type': 'show',
        'last_watched': raw,
      });
      expect(history.lastWatched, expected);
    }
    expect(show(1).lastWatched, isNull);
  });
}
