/// Lightweight show shape returned by the recommendations/similar endpoints —
/// no need to pull in the full TmdbShow model for a poster rail.
class RecommendedShow {
  final int id;
  final String name;
  final String? posterPath;
  final double voteAverage;
  final DateTime? firstAirDate;

  RecommendedShow({
    required this.id,
    required this.name,
    this.posterPath,
    required this.voteAverage,
    required this.firstAirDate,
  });

  factory RecommendedShow.fromJson(Map<String, dynamic> json) =>
      RecommendedShow(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        posterPath: json['poster_path'],
        voteAverage: (json['vote_average'] ?? 0).toDouble(),
        firstAirDate: json['first_air_date'] != null
            ? DateTime.parse(json['first_air_date'])
            : null,
      );
}
