import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';

class WatchStatsSnapshot {
  final int shows;
  final int movies;
  final int episodes;
  final int plays;
  final int showsThisMonth;
  final int moviesThisMonth;
  final int episodesThisMonth;
  final double episodesPerDay;
  final Map<DateTime, int> activityByDay;
  final DateTime month;

  const WatchStatsSnapshot({
    required this.shows,
    required this.movies,
    required this.episodes,
    required this.plays,
    required this.showsThisMonth,
    required this.moviesThisMonth,
    required this.episodesThisMonth,
    required this.episodesPerDay,
    required this.activityByDay,
    required this.month,
  });

  static WatchStatsSnapshot fromHistory(List<WatchHistoryItem> history, {DateTime? month}) {
    final now = DateTime.now();
    final focus = month ?? DateTime(now.year, now.month);
    final monthStart = DateTime(focus.year, focus.month);
    final monthEnd = DateTime(focus.year, focus.month + 1);

    final latest = <int, WatchHistoryItem>{};
    for (final item in history) {
      final existing = latest[item.tmdbId];
      if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
        latest[item.tmdbId] = item;
      }
    }

    var shows = 0;
    var movies = 0;
    var episodes = 0;
    var plays = 0;
    var showsThisMonth = 0;
    var moviesThisMonth = 0;
    var episodesThisMonth = 0;
    DateTime? first;
    final activity = <DateTime, int>{};

    void addDay(DateTime raw, int count) {
      final day = DateTime(raw.year, raw.month, raw.day);
      activity[day] = (activity[day] ?? 0) + count;
      first = first == null || raw.isBefore(first!) ? raw : first;
    }

    bool inMonth(DateTime local) => !local.isBefore(monthStart) && local.isBefore(monthEnd);

    for (final item in latest.values) {
      if (item.mediaType == MediaType.movie) {
        if (item.completion <= 0) continue;
        movies++;
        final when = (item.watchedAt ?? item.updatedAt).toLocal();
        final count = item.plays > 0 ? item.plays : 1;
        plays += count;
        addDay(when, count);
        if (inMonth(when)) moviesThisMonth++;
      } else {
        final watchedEps = item.episodes.where((e) => e.completion > 0).toList();
        if (watchedEps.isEmpty) continue;
        shows++;
        var monthHit = false;
        for (final ep in watchedEps) {
          episodes++;
          final count = ep.plays > 0 ? ep.plays : 1;
          plays += count;
          final when = (ep.watchedAt ?? item.updatedAt).toLocal();
          addDay(when, count);
          if (inMonth(when)) {
            episodesThisMonth += count;
            monthHit = true;
          }
        }
        if (monthHit) showsThisMonth++;
      }
    }

    final spanDays = first == null ? 1 : now.difference(first!).inDays.clamp(1, 36500);
    return WatchStatsSnapshot(
      shows: shows,
      movies: movies,
      episodes: episodes,
      plays: plays,
      showsThisMonth: showsThisMonth,
      moviesThisMonth: moviesThisMonth,
      episodesThisMonth: episodesThisMonth,
      episodesPerDay: episodes / spanDays,
      activityByDay: activity,
      month: monthStart,
    );
  }
}
