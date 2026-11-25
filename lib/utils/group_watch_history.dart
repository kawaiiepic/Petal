import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

/// One entry per title, newest first. If a show occurs in multiple snapshots,
/// the newest snapshot for each episode wins, including its play indices.
List<WatchHistoryItem> groupWatchHistory(List<WatchHistoryItem> history) {
  final sorted = [...history]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final byTitle = <(MediaType, int), List<WatchHistoryItem>>{};
  for (final item in sorted) {
    (byTitle[(item.mediaType, item.tmdbId)] ??= []).add(item);
  }
  return [for (final snapshots in byTitle.values) _mergeTitle(snapshots)];
}

WatchHistoryItem _mergeTitle(List<WatchHistoryItem> snapshots) {
  final latest = snapshots.first;
  if (latest.mediaType == MediaType.movie) return latest;
  final episodes = <(int, int), EpisodeProgress>{};
  for (final snapshot in snapshots) {
    for (final episode in snapshot.episodes.reversed) {
      episodes.putIfAbsent((episode.season, episode.episode), () => episode);
    }
  }
  return WatchHistoryItem(
    tmdbId: latest.tmdbId,
    mediaType: latest.mediaType,
    completion: latest.completion,
    updatedAt: latest.updatedAt,
    lastWatched: latest.lastWatched,
    watchedAt: latest.watchedAt,
    plays: latest.plays,
    watches: latest.watches,
    episodes: episodes.values.toList().reversed.toList(),
  );
}
