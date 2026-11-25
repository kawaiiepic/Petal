import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

class CollectionHistoryEntry {
  final WatchHistoryItem item;
  final Object? metadata;
  const CollectionHistoryEntry({required this.item, this.metadata});

  int? get episodeCount {
    final show = metadata;
    if (show is! TmdbShow) return null;
    final last = show.lastEpisodeToAir;
    if (last != null && last.seasonNumber > 0 && last.episodeNumber > 0) {
      final earlier = show.mainSeasons.where((s) => s.seasonNumber < last.seasonNumber);
      // Count only already aired regular episodes, not announced future episodes.
      if (earlier.length == last.seasonNumber - 1) {
        return earlier.fold<int>(last.episodeNumber, (sum, s) => sum + s.episodeCount);
      }
    }
    return show.numberOfEpisodes > 0 ? show.numberOfEpisodes : null;
  }
  String? get artworkPath {
    final (backdrop, poster) = switch (metadata) {
      TmdbShow show => (show.backdropPath, show.posterPath),
      TmdbMovie movie => (movie.backdropPath, movie.posterPath),
      _ => (null, null),
    };
    return backdrop == null || backdrop.isEmpty ? poster : backdrop;
  }

  String get title {
    final name = switch (metadata) {
      TmdbShow show => show.name,
      TmdbMovie movie => movie.title,
      _ => null,
    };
    return name == null || name.trim().isEmpty
        ? '${item.mediaType == MediaType.show ? 'Show' : 'Movie'} ${item.tmdbId}'
        : name;
  }
}
