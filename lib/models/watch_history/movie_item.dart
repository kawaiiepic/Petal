import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';

class MovieItem extends ContinueWatchingItem {
  final double completion;

  MovieItem({required super.tmdbId, required this.completion})
    : super(mediaType: MediaType.movie);

  factory MovieItem.fromJson(Map<String, dynamic> json) {
    return MovieItem(
      tmdbId: (json['tmdb_id'] as num).toInt(),
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
