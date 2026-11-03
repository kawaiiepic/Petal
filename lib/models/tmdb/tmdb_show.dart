import 'package:petal/models/tmdb/created_by.dart';
import 'package:petal/models/tmdb/episode_summary.dart';
import 'package:petal/models/tmdb/genre.dart';
import 'package:petal/models/tmdb/network.dart';
import 'package:petal/models/tmdb/season_summary.dart';
import 'package:petal/models/tmdb/tmdb_credits.dart';
import 'package:petal/models/tmdb/tmdb_images.dart';
import 'package:petal/models/tmdb/tmdb_show_recommendations.dart';
import 'package:petal/models/tmdb/tmdb_videos.dart';

class TmdbShow {
  final bool adult;
  final String? backdropPath;
  final List<CreatedBy> createdBy;
  final List<int> episodeRunTime;
  final String firstAirDate;
  final String lastAirDate;
  final List<Genre> genres;
  final String homepage;
  final int id;
  final bool inProduction;
  final List<String> languages;
  final EpisodeSummary? lastEpisodeToAir;
  final String name;
  final String originalName;
  final String overview;
  final double popularity;
  final String? posterPath;
  final List<Network> networks;
  final int numberOfEpisodes;
  final int numberOfSeasons;
  final List<String> originCountry;
  final List<SeasonSummary> seasons;
  final String status;
  final String tagline;
  final String type;
  final double voteAverage;
  final int voteCount;
  final TmdbImages? images;
  final TmdbVideos? videos;
  final TmdbCredits? credits;
  final TmdbShowRecommendations? recommendations;

  final String? imdbId;

  static const _imageBase = 'https://image.tmdb.org/t/p/w500';
  static const _backdropBase = 'https://image.tmdb.org/t/p/original';

  TmdbShow({
    required this.adult,
    required this.backdropPath,
    required this.createdBy,
    required this.episodeRunTime,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.genres,
    required this.homepage,
    required this.id,
    required this.inProduction,
    required this.languages,
    required this.lastEpisodeToAir,
    required this.name,
    required this.originalName,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.networks,
    required this.numberOfEpisodes,
    required this.numberOfSeasons,
    required this.originCountry,
    required this.seasons,
    required this.status,
    required this.tagline,
    required this.type,
    required this.voteAverage,
    required this.voteCount,
    required this.images,
    required this.videos,
    required this.credits,
    required this.recommendations,

    required this.imdbId,
  });

  String? get posterUrl => posterPath != null ? '$_imageBase$posterPath' : null;
  String? get backdropUrl =>
      backdropPath != null ? '$_backdropBase$backdropPath' : null;

  List<SeasonSummary> get mainSeasons =>
      seasons.where((s) => s.seasonNumber > 0).toList();

  factory TmdbShow.fromJson(Map<String, dynamic> json) => TmdbShow(
    adult: json['adult'] ?? false,
    backdropPath: json['backdrop_path'],
    createdBy: (json['created_by'] as List? ?? [])
        .map((e) => CreatedBy.fromJson(e))
        .toList(),
    episodeRunTime: (json['episode_run_time'] as List? ?? [])
        .map((e) => e as int)
        .toList(),
    firstAirDate: json['first_air_date'] ?? '',
    lastAirDate: json['last_air_date'] ?? '',
    genres: (json['genres'] as List? ?? [])
        .map((e) => Genre.fromJson(e))
        .toList(),
    homepage: json['homepage'] ?? '',
    id: json['id'],
    inProduction: json['in_production'] ?? false,
    languages: (json['languages'] as List? ?? [])
        .map((e) => e as String)
        .toList(),
    lastEpisodeToAir: json['last_episode_to_air'] != null
        ? EpisodeSummary.fromJson(json['last_episode_to_air'])
        : null,
    name: json['name'] ?? '',
    originalName: json['original_name'] ?? '',
    overview: json['overview'] ?? '',
    popularity: (json['popularity'] ?? 0).toDouble(),
    posterPath: json['poster_path'],
    networks: (json['networks'] as List? ?? [])
        .map((e) => Network.fromJson(e))
        .toList(),
    numberOfEpisodes: json['number_of_episodes'] ?? 0,
    numberOfSeasons: json['number_of_seasons'] ?? 0,
    originCountry: (json['origin_country'] as List? ?? [])
        .map((e) => e as String)
        .toList(),
    seasons: (json['seasons'] as List? ?? [])
        .map((e) => SeasonSummary.fromJson(e))
        .toList(),
    status: json['status'] ?? '',
    tagline: json['tagline'] ?? '',
    type: json['type'] ?? '',
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    voteCount: json['vote_count'] ?? 0,
    images: json['images'] != null ? TmdbImages.fromJson(json['images']) : null,
    videos: json['videos'] != null ? TmdbVideos.fromJson(json['videos']) : null,
    credits: json['credits'] != null
        ? TmdbCredits.fromJson(json['credits'])
        : null,
    recommendations: json['recommendations'] != null
        ? TmdbShowRecommendations.fromJson(json['recommendations'])
        : null,
    imdbId: json['external_ids']?['imdb_id'],
  );
}
