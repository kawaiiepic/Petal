import 'package:petal/models/media_type.dart';

class RecentWatch {
  final int tmdbId;
  final MediaType type;
  final int? season;
  final int? episode;
  final DateTime at;

  const RecentWatch({
    required this.tmdbId,
    required this.type,
    required this.at,
    this.season,
    this.episode,
  });
}
