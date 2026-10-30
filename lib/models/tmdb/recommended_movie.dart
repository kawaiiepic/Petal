/// Lightweight movie shape returned by the recommendations/similar endpoints —
/// no need to pull in the full TmdbMovie model for a poster rail.
///
class RecommendedMovie {
  final int id;
  final String title;
  final String? posterPath;
  final double voteAverage;
  final DateTime? releaseDate;

  RecommendedMovie({
    required this.id,
    required this.title,
    this.posterPath,
    required this.voteAverage,
    required this.releaseDate,
  });

  factory RecommendedMovie.fromJson(Map<String, dynamic> json) =>
      RecommendedMovie(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        posterPath: json['poster_path'],
        voteAverage: (json['vote_average'] ?? 0).toDouble(),
        releaseDate: json['release_date'] != null
            ? DateTime.parse(json['release_date'])
            : null,
      );
}
