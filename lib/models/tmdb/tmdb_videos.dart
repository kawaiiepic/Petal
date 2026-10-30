import 'package:petal/models/tmdb/tmdb_video.dart';

class TmdbVideos {
  final List<TmdbVideo> results;

  TmdbVideos({required this.results});

  factory TmdbVideos.fromJson(Map<String, dynamic> json) => TmdbVideos(
    results: (json['results'] as List<dynamic>? ?? [])
        .map((e) => TmdbVideo.fromJson(e))
        .toList(),
  );
}
