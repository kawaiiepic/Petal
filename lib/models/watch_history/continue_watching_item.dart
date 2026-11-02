import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/show_item.dart';

abstract class ContinueWatchingItem {
  final DateTime? lastWatched;
  final int tmdbId;
  final MediaType mediaType;

  ContinueWatchingItem({
    required this.tmdbId,
    required this.mediaType,
    this.lastWatched,
  });

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String;
    if (mediaType == 'movie') {
      return MovieItem.fromJson(json);
    }
    return ShowItem.fromJson(json);
  }
}
