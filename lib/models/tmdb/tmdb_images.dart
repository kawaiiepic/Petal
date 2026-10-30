import 'package:petal/models/tmdb/tmdb_image.dart';

class TmdbImages {
  final List<TmdbImage> backdrops;
  final List<TmdbImage> posters;
  final List<TmdbImage> logos;

  TmdbImages({
    required this.backdrops,
    required this.posters,
    required this.logos,
  });

  factory TmdbImages.fromJson(Map<String, dynamic> json) => TmdbImages(
    backdrops: (json['backdrops'] as List? ?? [])
        .map((e) => TmdbImage.fromJson(e))
        .toList(),
    posters: (json['posters'] as List? ?? [])
        .map((e) => TmdbImage.fromJson(e))
        .toList(),
    logos: (json['logos'] as List? ?? [])
        .map((e) => TmdbImage.fromJson(e))
        .toList(),
  );
}
