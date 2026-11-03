import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/tmdb/tmdb_season.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/next_episode.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/show_playback.dart';

void main() {
  final show = TmdbShow.fromJson({
    'id': 42,
    'seasons': [
      {'id': 1, 'season_number': 1, 'episode_count': 2},
      {'id': 2, 'season_number': 2, 'episode_count': 2},
    ],
  });
  TmdbSeason season(int number, {bool future = false}) => TmdbSeason.fromJson({
    '_id': '$number', 'name': 'Season $number', 'season_number': number,
    'episodes': [
      for (var n = 1; n <= 2; n++)
        {'id': number * 10 + n, 'season_number': number,
          'episode_number': n, 'air_date': future ? '2099-01-01' : '2020-01-01'},
    ],
  });
  WatchHistoryItem history(List<(int, int, double)> entries) =>
      WatchHistoryItem.fromJson({
        'tmdb_id': 42, 'media_type': 'show', 'updated_at': 1,
        'episodes': [
          for (final entry in entries)
            {'season': entry.$1, 'episode': entry.$2, 'completion': entry.$3},
        ],
      });

  test('watched first episode advances Play to episode two', () async {
    final target = await ShowPlayback.resolve(show: show,
      history: [history([(1, 1, 1)])], nextUp: [],
      loadSeason: (n) async => season(n));
    expect(target.episode?.seasonNumber, 1);
    expect(target.episode?.episodeNumber, 2);
    expect(target.rewatch, false);
  });
  test('completed season advances Play and initial selection to next season', () async {
    final target = await ShowPlayback.resolve(show: show,
      history: [history([(1, 1, 1), (1, 2, 1)])], nextUp: [],
      loadSeason: (n) async => season(n));
    expect(target.episode?.seasonNumber, 2);
    expect(target.episode?.episodeNumber, 1);
  });
  test('partial episode resumes and stale next-up cannot replay a watched one', () async {
    final target = await ShowPlayback.resolve(show: show,
      history: [history([(1, 1, 1), (1, 2, 1), (2, 1, .4)])],
      nextUp: [ShowItem(tmdbId: 42,
        nextEpisode: NextEpisode(season: 1, episode: 1, completion: 0),
        seasons: [])], loadSeason: (n) async => season(n));
    expect(target.episode?.seasonNumber, 2);
    expect(target.episode?.episodeNumber, 1);
  });
  test('all aired episodes watched explicitly selects rewatch, skipping future episodes', () async {
    final target = await ShowPlayback.resolve(show: show,
      history: [history([(1, 1, 1), (1, 2, 1)])], nextUp: [],
      loadSeason: (n) async => season(n, future: n == 2));
    expect(target.episode?.seasonNumber, 1);
    expect(target.episode?.episodeNumber, 1);
    expect(target.rewatch, true);
  });
  test('unaired show has no playable target', () async {
    final target = await ShowPlayback.resolve(show: show, history: [],
      nextUp: [], loadSeason: (n) async => season(n, future: true));
    expect(target.episode, null);
    expect(target.rewatch, false);
  });
}
