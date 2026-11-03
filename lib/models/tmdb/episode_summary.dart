class EpisodeSummary {
  final int id;
  final String name;
  final String overview;
  final double voteAverage;
  final int voteCount;
  final String airDate;
  final int episodeNumber;
  final int seasonNumber;
  final int showId;
  final String productionCode;
  final int runtime;
  final String? stillPath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w500';

  EpisodeSummary({
    required this.id,
    required this.name,
    required this.overview,
    required this.voteAverage,
    required this.voteCount,
    required this.airDate,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.showId,
    required this.productionCode,
    required this.runtime,
    required this.stillPath,
  });

  String? get stillUrl => stillPath != null ? '$_imageBase$stillPath' : null;

  factory EpisodeSummary.fromJson(Map<String, dynamic> json) => EpisodeSummary(
    id: json['id'],
    name: json['name'] ?? '',
    overview: json['overview'] ?? '',
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    voteCount: json['vote_count'] ?? 0,
    airDate: json['air_date'] ?? '',
    episodeNumber: json['episode_number'],
    seasonNumber: json['season_number'],
    showId: json['show_id'],
    productionCode: json['production_code'] ?? '',
    runtime: json['runtime'] ?? 0,
    stillPath: json['still_path'],
  );
}
