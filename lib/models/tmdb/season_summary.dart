class SeasonSummary {
  final int id;
  final int seasonNumber;
  final String name;
  final String overview;
  final String? posterPath;
  final String airDate;
  final int episodeCount;
  final double voteAverage;

  static const _imageBase = 'https://image.tmdb.org/t/p/w500';

  SeasonSummary({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.airDate,
    required this.episodeCount,
    required this.voteAverage,
  });

  String? get posterUrl => posterPath != null ? '$_imageBase$posterPath' : null;

  /// A season's first air date, rather than the show's original premiere.
  String get releaseLabel {
    final date = DateTime.tryParse(airDate);
    if (date == null) return '$name · TBA';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$name · ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  factory SeasonSummary.fromJson(Map<String, dynamic> json) => SeasonSummary(
    id: json['id'],
    seasonNumber: json['season_number'],
    name: json['name'] ?? '',
    overview: json['overview'] ?? '',
    posterPath: json['poster_path'],
    airDate: json['air_date'] ?? '',
    episodeCount: json['episode_count'] ?? 0,
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
  );
}
