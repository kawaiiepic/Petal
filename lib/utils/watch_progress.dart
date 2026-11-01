import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

abstract final class WatchProgress {
  static const watchedThreshold = 0.9;
  static bool isWatched(double completion) => completion >= watchedThreshold;
  static bool isPartial(double completion) =>
      completion > 0 && !isWatched(completion);
  static double storedCompletion(double ratio) =>
      isWatched(ratio) ? 1 : ratio.clamp(0, 1);

  static bool titleInProgress({
    required int tmdbId,
    required MediaType type,
    required List<WatchHistoryItem> history,
    required List<ContinueWatchingItem> nextUp,
    int? totalEpisodes,
  }) {
    final current = nextUp.where(
      (item) => item.tmdbId == tmdbId && item.mediaType == type,
    );
    final previous =
        history
            .where((item) => item.tmdbId == tmdbId && item.mediaType == type)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (type == MediaType.movie) {
      return current.whereType<MovieItem>().any(
            (item) => isPartial(item.completion),
          ) ||
          (previous.isNotEmpty && isPartial(previous.first.completion));
    }
    final episodes = previous.isEmpty ? const [] : previous.first.episodes;
    if (episodes.any((episode) => isPartial(episode.completion))) return true;
    for (final show in current.whereType<ShowItem>()) {
      if (show.seasons.any(
        (season) =>
            season.episodes.any((episode) => isPartial(episode.completion)),
      ))
        return true;
      final started =
          episodes.any((episode) => episode.completion > 0) ||
          show.seasons.any(
            (season) =>
                season.episodes.any((episode) => episode.completion > 0),
          ) ||
          (show.nextEpisode?.completion ?? 0) > 0;
      if (started &&
          show.nextEpisode != null &&
          !isWatched(show.nextEpisode!.completion))
        return true;
    }
    final watched = episodes
        .where((episode) => isWatched(episode.completion))
        .length;
    return totalEpisodes != null && watched > 0 && watched < totalEpisodes;
  }
}
