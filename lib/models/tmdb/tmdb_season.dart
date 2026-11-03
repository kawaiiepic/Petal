import 'package:petal/models/tmdb/tmdb_episode.dart';

class TmdbSeason {
  final String id;
  final String? airDate;
  final List<TmdbEpisode> episodes;
  final String name;
  final String? overview;
  final String? posterPath;
  final int seasonNumber;
  final double voteAverage;

  const TmdbSeason({
    required this.id,
    this.airDate,
    required this.episodes,
    required this.name,
    this.overview,
    this.posterPath,
    required this.seasonNumber,
    required this.voteAverage,
  });

  factory TmdbSeason.fromJson(Map<String, dynamic> json) => TmdbSeason(
    id: json['_id'] as String,
    airDate: json['air_date'] as String?,
    episodes: (json['episodes'] as List<dynamic>)
        .map((e) => TmdbEpisode.fromJson(e as Map<String, dynamic>))
        .toList(),
    name: json['name'] as String,
    overview: json['overview'] as String?,
    posterPath: json['poster_path'] as String?,
    seasonNumber: json['season_number'] as int,
    voteAverage: (json['vote_average'] as num).toDouble(),
  );
}
