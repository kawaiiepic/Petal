import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/group_watch_history.dart';

class HistoryPlay {
  final WatchHistoryItem item;
  final EpisodeProgress? episode;
  final DateTime? date;
  final int index;
  const HistoryPlay(this.item, this.episode, this.date, this.index);
  Object get key => (item.mediaType, item.tmdbId, episode?.season, episode?.episode, date, index);
}

List<HistoryPlay> historyTimeline(List<WatchHistoryItem> history) {
  final plays = <HistoryPlay>[];
  for (final item in groupWatchHistory(history)) {
    if (item.mediaType == MediaType.movie) {
      if (item.watches.isEmpty) {
        plays.add(HistoryPlay(item, null, item.watchedAt ?? item.lastWatched, 0));
      } else {
        for (var i = 0; i < item.watches.length; i++) {
          plays.add(HistoryPlay(item, null, item.watches[i], i));
        }
      }
    } else {
      for (final episode in item.episodes) {
        if (episode.watches.isEmpty) {
          plays.add(HistoryPlay(item, episode, episode.watchedAt, 0));
        } else {
          for (var i = 0; i < episode.watches.length; i++) {
            plays.add(HistoryPlay(item, episode, episode.watches[i], i));
          }
        }
      }
    }
  }
  plays.sort((a, b) {
    final first = a.date, second = b.date;
    if (first == null) return second == null ? 0 : 1;
    if (second == null) return -1;
    return second.compareTo(first);
  });
  return plays;
}
