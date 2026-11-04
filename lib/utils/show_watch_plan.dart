import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_season.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

typedef ShowEpisodeTarget = ({int season, int episode});

abstract final class ShowWatchPlan {
  static Future<List<ShowEpisodeTarget>> load(TmdbShow show, {
    required Future<TmdbSeason> Function(int) loadSeason, DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final seasons = show.seasons.map((s) => s.seasonNumber)
        .where((s) => s >= 0).toSet().toList()..sort();
    final targets = <ShowEpisodeTarget>{};
    for (final number in seasons) {
      final season = await loadSeason(number);
      for (final ep in season.episodes) {
        if (ep.episodeNumber < 1 || ep.seasonNumber < 0) continue;
        if (ep.airDate != null && ep.airDate!.isAfter(today)) continue;
        targets.add((season: ep.seasonNumber, episode: ep.episodeNumber));
      }
    }
    return targets.toList()..sort((a, b) {
      final order = a.season.compareTo(b.season);
      return order == 0 ? a.episode.compareTo(b.episode) : order;
    });
  }

  static WatchHistoryItem optimistic(int id, List<WatchHistoryItem> history,
      List<ShowEpisodeTarget> targets, double completion, DateTime now) {
    final before = <ShowEpisodeTarget, EpisodeProgress>{};
    for (final row in history.where((h) => h.tmdbId == id && h.mediaType == MediaType.show)) {
      for (final ep in row.episodes) before[(season: ep.season, episode: ep.episode)] = ep;
    }
    for (final target in targets) {
      final old = before[target];
      final watches = [...?old?.watches];
      var plays = old?.plays ?? 0;
      if (plays < watches.length) plays = watches.length;
      if ((old?.completion ?? 0) >= 1 && plays < 1) plays = 1;
      if (completion >= 1 && (old?.completion ?? 0) < 1) { watches.add(now); plays++; }
      before[target] = EpisodeProgress(season: target.season, episode: target.episode,
        completion: completion, plays: plays,
        watches: watches, watchedAt: watches.isEmpty ? old?.watchedAt : watches.last);
    }
    return WatchHistoryItem(tmdbId: id, mediaType: MediaType.show,
      completion: completion, updatedAt: now, episodes: before.values.toList());
  }

  static Future<void> saveVerified({
    required List<ShowEpisodeTarget> targets, required double completion,
    required Future<void> Function(List<ShowEpisodeTarget>) write,
    required Future<List<EpisodeProgress>> Function() read,
  }) async {
    var remaining = targets;
    for (var attempt = 0; attempt < 2; attempt++) {
      await write(remaining);
      remaining = missing(targets, await read(), completion);
      if (remaining.isEmpty) return;
    }
    throw StateError('${remaining.length} episodes were not confirmed saved. Please retry.');
  }

  static List<ShowEpisodeTarget> missing(List<ShowEpisodeTarget> targets,
      List<EpisodeProgress> saved, double completion) {
    final values = {for (final e in saved)
      (season: e.season, episode: e.episode): e.completion};
    return targets.where((t) => completion >= 1
      ? (values[t] ?? 0) < 1 : (values[t] ?? 0) > 0).toList();
  }
}
