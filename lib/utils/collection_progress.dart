import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

bool isWatching(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie) {
    return item.completion > 0 && item.completion < 1;
  }

  final anyInProgress = item.episodes.any(
    (e) => e.completion > 0 && e.completion < 1,
  );
  if (anyInProgress) return true;

  final anyStarted = item.episodes.any((e) => e.completion > 0);
  if (!anyStarted) return false;

  if (tmdbEpisodeCount != null && tmdbEpisodeCount > 0) {
    final done = item.episodes.where((e) => e.completion >= 1).length;
    return done < tmdbEpisodeCount;
  }
  return true;
}

bool isFinished(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie) return item.completion >= 1;

  final anyInProgress = item.episodes.any(
    (e) => e.completion > 0 && e.completion < 1,
  );
  if (anyInProgress) return false;

  final done = item.episodes.where((e) => e.completion >= 1).length;
  if (tmdbEpisodeCount != null && tmdbEpisodeCount > 0) {
    return done >= tmdbEpisodeCount;
  }
  return false;
}

bool isPlanned(WatchHistoryItem item) {
  if (item.mediaType == MediaType.movie) return item.completion <= 0;
  return item.episodes.isEmpty || item.episodes.every((e) => e.completion <= 0);
}
