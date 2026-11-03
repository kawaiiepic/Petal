import 'package:petal/models/tmdb/recommended_movie.dart';

class TmdbMovieRecommendations {
  final List<RecommendedMovie> results;

  TmdbMovieRecommendations({required this.results});

  factory TmdbMovieRecommendations.fromJson(Map<String, dynamic> json) =>
      TmdbMovieRecommendations(
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => RecommendedMovie.fromJson(e))
            .toList(),
      );
}
