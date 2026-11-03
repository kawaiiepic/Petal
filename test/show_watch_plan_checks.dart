import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/tmdb/tmdb_season.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/show_watch_plan.dart';

Future<void> main() async {
  final now = DateTime.utc(2026, 11, 3);
  final show = TmdbShow.fromJson({'id': 42, 'seasons': [
    {'id': 10, 'season_number': 0, 'episode_count': 1},
    {'id': 11, 'season_number': 1, 'episode_count': 0},
    {'id': 12, 'season_number': 2, 'episode_count': 1},
  ]});
  TmdbEpisode ep(int s, int e, {String? date = '2026-01-01'}) =>
    TmdbEpisode.fromJson({'id': s * 100 + e, 'season_number': s,
      'episode_number': e, 'air_date': date});
  Future<TmdbSeason> season(int n) async => TmdbSeason(
    id: '$n', name: 'Season $n', seasonNumber: n, voteAverage: 0,
    episodes: n == 0 ? [ep(0, 1)] : n == 1
      ? [ep(1, 1), ep(1, 3), ep(1, 7), ep(1, 3)]
      : [ep(2, 1, date: '2027-01-01'), ep(2, 2, date: null)],
  );
  final plan = await ShowWatchPlan.load(show, loadSeason: season, now: now);
  assert(plan.length == 5);
  assert(plan.contains((season: 0, episode: 1)));
  assert(plan.contains((season: 1, episode: 7)));
  assert(!plan.contains((season: 1, episode: 2)));
  assert(!plan.contains((season: 2, episode: 1)));
  assert(plan.contains((season: 2, episode: 2)));
  print('PASS actual episode numbers include specials and unknown counts without invented targets');

  final before = [WatchHistoryItem(tmdbId: 42, mediaType: MediaType.show,
    completion: .2, updatedAt: now, episodes: [
      EpisodeProgress(season: 1, episode: 1, completion: 1, plays: 5,
        watches: [DateTime.utc(2026, 1, 1)]),
      EpisodeProgress(season: 1, episode: 3, completion: .2),
    ])];
  final local = ShowWatchPlan.optimistic(42, before, plan, 1, now);
  assert(local.episodes.length == 5);
  assert(local.episodes.firstWhere((e) => e.season == 1 && e.episode == 1).plays == 5);
  assert(local.episodes.firstWhere((e) => e.season == 1 && e.episode == 3).plays == 1);
  final again = ShowWatchPlan.optimistic(42, [local], plan, 1, now);
  assert(again.episodes.firstWhere((e) => e.season == 1 && e.episode == 3).plays == 1);
  assert(ShowWatchPlan.missing(plan, local.episodes, 1).isEmpty);
  print('PASS optimistic progress covers the plan and keeps historical counts/dates');

  final writes = <List<ShowEpisodeTarget>>[];
  var reads = 0;
  await ShowWatchPlan.saveVerified(targets: plan, completion: 1,
    write: (rows) async { writes.add([...rows]); },
    read: () async => ++reads == 1 ? local.episodes.where((e) => e.season != plan.first.season || e.episode != plan.first.episode).toList() : local.episodes,
  );
  assert(writes.length == 2 && writes[1].length == 1);
  assert(writes[1].single == plan.first);
  var failed = false;
  try {
    await ShowWatchPlan.saveVerified(targets: plan, completion: 1,
      write: (_) async {}, read: () async => []);
  } on StateError { failed = true; }
  assert(failed);
  failed = false;
  try {
    await ShowWatchPlan.saveVerified(targets: plan, completion: 1,
      write: (_) async { throw StateError('network failed'); },
      read: () async => local.episodes);
  } on StateError { failed = true; }
  assert(failed);
  print('PASS readback retries only missing episodes and failures never report success');

  failed = false;
  try {
    await ShowWatchPlan.load(show, loadSeason: (_) async =>
      throw StateError('metadata failed'), now: now);
  } on StateError { failed = true; }
  assert(failed);
  print('PASS missing season metadata stops the action instead of guessing episode one');
}
