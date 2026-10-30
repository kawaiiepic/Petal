import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/imports/import_file_parser.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/imports/import_source.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_models.dart';
import 'package:petal/utils/collection_progress.dart';

void main() {
  group('API model contracts', () {
    test('catalog exports still expose nested extras', () {
      final catalog = Catalog.fromJson({
        'id': 'popular',
        'type': 'movie',
        'extra': [
          {'name': 'search', 'isRequired': true},
        ],
      });
      expect(catalog.extra.single, isA<CatalogExtra>());
      expect(catalog.extra.single.name, 'search');
    });

    test('continue watching dispatches movies and nested show progress', () {
      final movie = ContinueWatchingItem.fromJson({
        'tmdb_id': 10,
        'media_type': 'movie',
        'completion': 0.5,
      });
      final show = ContinueWatchingItem.fromJson({
        'tmdb_id': 11,
        'media_type': 'show',
        'next_episode': {'season': 2, 'episode': 3},
        'seasons': [
          {
            'number': 2,
            'episodes': [
              {'episode': 2, 'completion': 1},
            ],
          },
        ],
      });
      expect(movie, isA<MovieItem>());
      expect((movie as MovieItem).completion, 0.5);
      expect(show, isA<ShowItem>());
      expect((show as ShowItem).nextEpisode!.episode, 3);
      expect(show.seasons.single.episodes.single.completion, 1.0);
    });

    test('watch history retains timestamp and play-count fallbacks', () {
      final item = WatchHistoryItem.fromJson({
        'tmdb_id': 11,
        'media_type': 'show',
        'updated_at': 1700000000,
        'episodes': [
          {
            'season': 1,
            'episode': 2,
            'completion': 0.75,
            'watched_at': 1700000001,
            'watches': [0, 1700000002, 1700000003],
          },
        ],
      });
      expect(item.mediaType, MediaType.show);
      expect(item.completion, 0.75);
      expect(item.episodes.single.plays, 2);
      expect(
        item.episodes.single.watchedAt!.millisecondsSinceEpoch,
        1700000003000,
      );
      expect(item.updatedAt.millisecondsSinceEpoch, 1700000000000);
    });

    test('download persistence round trips and handles unknown statuses', () {
      final original = DownloadEntry(
        id: 'show-11-1-2',
        title: 'Episode',
        tmdbId: 11,
        season: 1,
        episode: 2,
        status: DownloadStatus.done,
        progress: 1,
        path: '/downloads/episode.mp4',
      );
      final restored = DownloadEntry.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
      expect(restored.isShow, isTrue);
      expect(
        DownloadEntry.fromJson({'id': 'old', 'status': 'legacy'}).status,
        DownloadStatus.queued,
      );
    });

    test('TMDB show decodes nested models through aggregate exports', () {
      final show = TmdbShow.fromJson({
        'id': 11,
        'name': 'Example',
        'seasons': [
          {'id': 1, 'season_number': 0, 'name': 'Specials'},
          {'id': 2, 'season_number': 1, 'name': 'Season 1'},
        ],
        'credits': {
          'cast': [
            {'id': 3, 'name': 'Actor'},
          ],
        },
        'external_ids': {'imdb_id': 'tt123'},
      });
      expect(show.mainSeasons.single.name, 'Season 1');
      expect(show.credits!.cast.single.name, 'Actor');
      expect(show.imdbId, 'tt123');
    });
  });

  group('collection progress', () {
    WatchHistoryItem history(
      String type,
      double completion, [
      List<Map<String, Object>> episodes = const [],
    ]) => WatchHistoryItem.fromJson({
      'tmdb_id': 10,
      'media_type': type,
      'completion': completion,
      'episodes': episodes,
    });

    test('movie status boundaries remain unchanged', () {
      expect(isPlanned(history('movie', 0)), isTrue);
      expect(isWatching(history('movie', 0.5)), isTrue);
      expect(isFinished(history('movie', 1)), isTrue);
      expect(isWatching(history('movie', 1)), isFalse);
    });

    test('shows require the total episode count to be finished', () {
      final item = history('show', 0, [
        {'season': 1, 'episode': 1, 'completion': 1},
        {'season': 1, 'episode': 2, 'completion': 1},
      ]);
      expect(isFinished(item), isFalse);
      expect(isFinished(item, tmdbEpisodeCount: 2), isTrue);
      expect(isWatching(item, tmdbEpisodeCount: 3), isTrue);
      expect(isWatching(item, tmdbEpisodeCount: 2), isFalse);
    });
  });

  group('import file parsing', () {
    Uint8List bytes(String value) => Uint8List.fromList(utf8.encode(value));

    test('CSV quotes, escaped quotes and trailing columns survive', () {
      expect(ImportFileParser.splitCsvRow('"Movie, The","a ""quote""",2024,'), [
        'Movie, The',
        'a "quote"',
        '2024',
        '',
      ]);
    });

    test('source detection preserves filename and content precedence', () {
      expect(
        ImportFileParser.detectSource('export.csv', bytes('{}')),
        ImportSource.letterboxd,
      );
      expect(
        ImportFileParser.detectSource('export.json', bytes('{"simkl_id":1}')),
        ImportSource.simkl,
      );
      expect(
        ImportFileParser.detectSource('history.json', bytes('[]')),
        ImportSource.trakt,
      );
    });

    test('record counts preserve format-specific progress totals', () {
      expect(
        ImportFileParser.countItems(
          'export.csv',
          bytes('name\nA\nB\n'),
          ImportSource.letterboxd,
        ),
        2,
      );
      expect(
        ImportFileParser.countItems(
          'export.json',
          bytes('{"movies":[{}],"tv":[{},{}]}'),
          ImportSource.simkl,
        ),
        3,
      );
      expect(
        ImportFileParser.countItems(
          'user-profile.json',
          bytes('{}'),
          ImportSource.trakt,
        ),
        0,
      );
    });

    test(
      'TMDB IDs accept direct and nested numeric/string representations',
      () {
        expect(ImportFileParser.tmdbId({'tmdb_id': '42'}), 42);
        expect(
          ImportFileParser.tmdbId({
            'ids': {'tmdb': 43},
          }),
          43,
        );
        expect(
          ImportFileParser.tmdbId({
            'ids': {'tmdb_id': '44'},
          }),
          44,
        );
        expect(ImportFileParser.tmdbId(null), isNull);
      },
    );
  });
}
