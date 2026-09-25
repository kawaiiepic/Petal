import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';

class DayWatch {
  final int tmdbId;
  final MediaType type;
  final int? season;
  final int? episode;
  final DateTime at;

  const DayWatch({required this.tmdbId, required this.type, required this.at, this.season, this.episode});
}

class WatchStatsSnapshot {
  final int shows;
  final int movies;
  final int episodes;
  final int plays;
  final int showsThisMonth;
  final int moviesThisMonth;
  final int episodesThisMonth;
  final double episodesPerDay;
  final int streak;
  final Map<DateTime, int> activityByDay;
  final Map<DateTime, List<DayWatch>> titlesByDay;
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
    required this.streak,
    required this.activityByDay,
    required this.titlesByDay,
    required this.month,
  });

  static int _streakFor(Map<DateTime, int> activity) {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if ((activity[day] ?? 0) == 0) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while ((activity[day] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

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
    final titles = <DateTime, List<DayWatch>>{};

    void addEvent(DateTime raw, DayWatch watch) {
      final day = DateTime(raw.year, raw.month, raw.day);
      activity[day] = (activity[day] ?? 0) + 1;
      titles.putIfAbsent(day, () => []).add(watch);
      first = first == null || raw.isBefore(first!) ? raw : first;
    }

    bool inMonth(DateTime local) => !local.isBefore(monthStart) && local.isBefore(monthEnd);

    List<DateTime> datesFor(List<DateTime> watches, DateTime? fallback) {
      if (watches.isNotEmpty) return watches.map((d) => d.toLocal()).toList();
      if (fallback != null) return [fallback.toLocal()];
      return const [];
    }

    for (final item in latest.values) {
      if (item.mediaType == MediaType.movie) {
        if (item.completion <= 0) continue;
        movies++;
        final dates = datesFor(item.watches, item.watchedAt ?? item.updatedAt);
        plays += dates.length;
        var monthHit = false;
        for (final when in dates) {
          addEvent(when, DayWatch(tmdbId: item.tmdbId, type: MediaType.movie, at: when));
          if (inMonth(when)) monthHit = true;
        }
        if (monthHit) moviesThisMonth++;
      } else {
        final watchedEps = item.episodes.where((e) => e.completion > 0).toList();
        if (watchedEps.isEmpty) continue;
        shows++;
        var monthHit = false;
        for (final ep in watchedEps) {
          episodes++;
          final dates = datesFor(ep.watches, ep.watchedAt ?? item.updatedAt);
          plays += dates.isEmpty ? 1 : dates.length;
          for (final when in dates) {
            addEvent(when, DayWatch(tmdbId: item.tmdbId, type: MediaType.show, at: when, season: ep.season, episode: ep.episode));
            if (inMonth(when)) {
              episodesThisMonth++;
              monthHit = true;
            }
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
      streak: _streakFor(activity),
      activityByDay: activity,
      titlesByDay: titles,
      month: monthStart,
    );
  }
}
