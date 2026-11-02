import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/watch_progress.dart';

bool isWatching(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie) {
    return WatchProgress.isPartial(item.completion);
  }

  final anyInProgress = item.episodes.any(
    (e) => WatchProgress.isPartial(e.completion),
  );
  if (anyInProgress) return true;

  final anyStarted = item.episodes.any((e) => e.completion > 0);
  if (!anyStarted) return false;

  if (tmdbEpisodeCount != null && tmdbEpisodeCount > 0) {
    return !isFinished(item, tmdbEpisodeCount: tmdbEpisodeCount);
  }
  return true;
}

bool isFinished(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie)
    return WatchProgress.isWatched(item.completion);

  return WatchProgress.titleFinished(
    tmdbId: item.tmdbId,
    type: item.mediaType,
    totalEpisodes: tmdbEpisodeCount,
    history: [item],
  );
}

bool isPlanned(WatchHistoryItem item) {
  if (item.mediaType == MediaType.movie) return item.completion <= 0;
  return item.episodes.isEmpty || item.episodes.every((e) => e.completion <= 0);
}
