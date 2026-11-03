import 'package:petal/models/tmdb/recommended_show.dart';

class TmdbShowRecommendations {
  final List<RecommendedShow> results;

  TmdbShowRecommendations({required this.results});

  factory TmdbShowRecommendations.fromJson(Map<String, dynamic> json) =>
      TmdbShowRecommendations(
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => RecommendedShow.fromJson(e))
            .toList(),
      );
}
