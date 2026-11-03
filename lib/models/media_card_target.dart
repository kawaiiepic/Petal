import 'package:petal/models/media_type.dart';

/// Identifies a title (and optionally an episode) for shared card actions.
class MediaCardTarget {
  final int? tmdbId;
  final String? imdbId;
  final MediaType type;
  final int? season;
  final int? episode;
  final int? totalEpisodes;

  const MediaCardTarget({
    this.tmdbId,
    this.imdbId,
    required this.type,
    this.season,
    this.episode,
    this.totalEpisodes,
  }) : assert(tmdbId != null || imdbId != null);

  bool get isEpisode => season != null && episode != null;
}
