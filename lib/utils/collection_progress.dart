import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/watch_progress.dart';

bool isWatching(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie) {
    return WatchProgress.isPartial(item.completion);
  }

  if (isFinished(item, tmdbEpisodeCount: tmdbEpisodeCount)) return false;
  final episodes = item.episodes.where((e) => e.season > 0 && e.episode > 0);
  if (episodes.any((e) => WatchProgress.isPartial(e.completion))) return true;
  if (tmdbEpisodeCount == null || tmdbEpisodeCount <= 0) return false;
  return episodes.any((e) => e.completion > 0);
}

bool isFinished(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie)
    return WatchProgress.isWatched(item.completion);

  if (tmdbEpisodeCount == null || tmdbEpisodeCount <= 0) return false;
  final watched = item.episodes
      .where((e) => e.season > 0 && e.episode > 0 &&
          WatchProgress.isWatched(e.completion))
      .map((e) => (e.season, e.episode)).toSet();
  return watched.length >= tmdbEpisodeCount;
}

bool isPlanned(WatchHistoryItem item) {
  if (item.mediaType == MediaType.movie) return item.completion <= 0;
  return item.episodes.isEmpty || item.episodes.every((e) => e.completion <= 0);
}
