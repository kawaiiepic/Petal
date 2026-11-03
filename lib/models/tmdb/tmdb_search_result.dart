import 'package:petal/models/tmdb/tmdb_media.dart';

class TmdbSearchResult {
  final List<TmdbMedia> movies;
  final List<TmdbMedia> tv;
  final List<TmdbMedia> people;

  TmdbSearchResult({
    required this.movies,
    required this.tv,
    required this.people,
  });

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List? ?? [])
        .map((e) => TmdbMedia.fromJson(e))
        .toList();

    return TmdbSearchResult(
      movies: (json['movie_results'] as List? ?? [])
          .map((e) => TmdbMedia.fromJson(e))
          .toList(),
      tv: (json['tv_results'] as List? ?? [])
          .map((e) => TmdbMedia.fromJson(e))
          .toList(),
      people: results.where((r) => r.mediaType == 'person').toList(),
    );
  }
}
