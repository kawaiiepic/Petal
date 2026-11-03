import 'package:petal/models/watch_history/watch_history_parsing.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/next_episode.dart';
import 'package:petal/models/watch_history/season.dart';

class ShowItem extends ContinueWatchingItem {
  final NextEpisode? nextEpisode;
  final List<Season> seasons;

  ShowItem({
    required super.tmdbId,
    super.lastWatched,
    required this.nextEpisode,
    required this.seasons,
  }) : super(mediaType: MediaType.show);

  factory ShowItem.fromJson(Map<String, dynamic> json) {
    return ShowItem(
      tmdbId: (json['tmdb_id'] as num).toInt(),
      lastWatched: lastWatchedFrom(json['last_watched']),
      nextEpisode: json['next_episode'] != null
          ? NextEpisode.fromJson(json['next_episode'] as Map<String, dynamic>)
          : null,
      seasons: (json['seasons'] as List<dynamic>? ?? [])
          .map((s) => Season.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
