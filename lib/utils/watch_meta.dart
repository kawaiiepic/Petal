import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/watch_progress.dart';

class WatchMeta {
  static String relative(DateTime date) {
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.month}/${local.day}';
  }

  static String minutes(int minutes) {
    if (minutes <= 0) return '';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  static int episodeMinutes(TmdbShow? show, {int? episodeRuntime}) {
    if (episodeRuntime != null && episodeRuntime > 0) return episodeRuntime;
    if (show != null &&
        show.episodeRunTime.isNotEmpty &&
        show.episodeRunTime.first > 0) {
      return show.episodeRunTime.first;
    }
    return 24;
  }

  static int airedEpisodes(TmdbShow show) {
    final seasons = show.mainSeasons;
    if (seasons.isEmpty) return show.numberOfEpisodes;
    final now = DateTime.now();
    var count = 0;
    for (final season in seasons) {
      if (season.airDate.isNotEmpty) {
        final air = DateTime.tryParse(season.airDate);
        if (air != null && air.isAfter(now)) continue;
      }
      count += season.episodeCount;
    }
    return count > 0 ? count : show.numberOfEpisodes;
  }

  static int watchedEpisodesFromShow(ShowItem show) {
    var count = 0;
    for (final season in show.seasons) {
      for (final episode in season.episodes) {
        if (WatchProgress.isWatched(episode.completion)) count++;
      }
    }
    return count;
  }

  static int watchedEpisodesFromHistory(WatchHistoryItem item) {
    return item.episodes
        .where((e) => WatchProgress.isWatched(e.completion))
        .length;
  }

  static String? remainingLabel({
    required int left,
    required int minutesEach,
    double currentCompletion = 0,
  }) {
    if (left <= 0) return null;
    var minutes = left * minutesEach;
    if (currentCompletion > 0 && currentCompletion < 1) {
      minutes =
          ((1 - currentCompletion) * minutesEach).round() +
          ((left - 1) * minutesEach);
    }
    final time = WatchMeta.minutes(minutes);
    if (time.isEmpty) return '$left left';
    return '$left left\n$time';
  }
}
