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

  /// Progress for a specific movie or episode, never an aggregate show ratio.
  static double? playbackCompletion({
    required int tmdbId,
    required MediaType type,
    int? season,
    int? episode,
    required List<WatchHistoryItem> history,
    required List<ContinueWatchingItem> nextUp,
  }) {
    if (type != MediaType.movie && (season == null || episode == null))
      return null;
    for (final item in nextUp.where(
      (item) => item.tmdbId == tmdbId && item.mediaType == type,
    )) {
      if (item is MovieItem) return item.completion;
      if (item is ShowItem) {
        final next = item.nextEpisode;
        if (next?.season == season && next?.episode == episode)
          return next!.completion;
      }
    }
    final matches =
        history
            .where((item) => item.tmdbId == tmdbId && item.mediaType == type)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (matches.isNotEmpty) {
      if (type == MediaType.movie) return matches.first.completion;
      for (final entry in matches.first.episodes) {
        if (entry.season == season && entry.episode == episode)
          return entry.completion;
      }
    }
    for (final item in nextUp.whereType<ShowItem>().where(
      (item) => item.tmdbId == tmdbId && type == MediaType.show,
    )) {
      for (final entry in item.seasons.where(
        (entry) => entry.number == season,
      )) {
        for (final part in entry.episodes) {
          if (part.episode == episode) return part.completion;
        }
      }
    }
    return null;
  }

  static bool titleFinished({
    required int tmdbId,
    required MediaType type,
    required List<WatchHistoryItem> history,
    int? totalEpisodes,
  }) {
    final matches =
        history
            .where((item) => item.tmdbId == tmdbId && item.mediaType == type)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (matches.isEmpty) return false;
    final item = matches.first;
    if (type == MediaType.movie) return isWatched(item.completion);
    if (totalEpisodes == null || totalEpisodes <= 0) return false;
    final episodes = item.episodes.where(
      (episode) => episode.season > 0 && episode.episode > 0,
    );
    if (episodes.any((episode) => isPartial(episode.completion))) return false;
    final watched = episodes
        .where((episode) => isWatched(episode.completion))
        .map((episode) => '${episode.season}:${episode.episode}')
        .toSet();
    return watched.length >= totalEpisodes;
  }

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
