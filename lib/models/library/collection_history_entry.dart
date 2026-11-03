import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

class CollectionHistoryEntry {
  final WatchHistoryItem item;
  final Object? metadata;
  const CollectionHistoryEntry({required this.item, this.metadata});

  int? get episodeCount =>
      metadata is TmdbShow ? (metadata as TmdbShow).numberOfEpisodes : null;
  String? get posterPath => switch (metadata) {
    TmdbShow show => show.posterPath,
    TmdbMovie movie => movie.posterPath,
    _ => null,
  };
}
