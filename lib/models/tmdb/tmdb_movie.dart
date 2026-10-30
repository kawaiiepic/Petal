import 'package:petal/models/tmdb/collection.dart';
import 'package:petal/models/tmdb/genre.dart';
import 'package:petal/models/tmdb/production_company.dart';
import 'package:petal/models/tmdb/production_country.dart';
import 'package:petal/models/tmdb/spoken_language.dart';
import 'package:petal/models/tmdb/tmdb_credits.dart';
import 'package:petal/models/tmdb/tmdb_images.dart';
import 'package:petal/models/tmdb/tmdb_movie_recommendations.dart';
import 'package:petal/models/tmdb/tmdb_videos.dart';

class TmdbMovie {
  final bool adult;
  final String? backdropPath;
  final Collection? belongsToCollection;
  final int budget;
  final List<Genre> genres;
  final String? homepage;
  final int id;
  final String? imdbId;
  final List<String> originCountry;
  final String originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String? posterPath;
  final List<ProductionCompany> productionCompanies;
  final List<ProductionCountry> productionCountries;
  final DateTime releaseDate;
  final int revenue;
  final int? runtime;
  final List<SpokenLanguage> spokenLanguages;
  final String status;
  final String? tagline;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;
  final TmdbImages? images;
  final TmdbVideos? videos;
  final TmdbCredits? credits;
  final TmdbMovieRecommendations? recommendations;

  TmdbMovie({
    required this.adult,
    this.backdropPath,
    this.belongsToCollection,
    required this.budget,
    required this.genres,
    this.homepage,
    required this.id,
    this.imdbId,
    required this.originCountry,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    this.posterPath,
    required this.productionCompanies,
    required this.productionCountries,
    required this.releaseDate,
    required this.revenue,
    this.runtime,
    required this.spokenLanguages,
    required this.status,
    this.tagline,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
    required this.images,
    required this.videos,
    required this.credits,
    required this.recommendations,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) => TmdbMovie(
    adult: json['adult'] ?? false,
    backdropPath: json['backdrop_path'],
    belongsToCollection: json['belongs_to_collection'] != null
        ? Collection.fromJson(json['belongs_to_collection'])
        : null,
    budget: json['budget'] ?? 0,
    genres: (json['genres'] as List<dynamic>? ?? [])
        .map((e) => Genre.fromJson(e))
        .toList(),
    homepage: json['homepage'],
    id: json['id'] ?? 0,
    imdbId: json['imdb_id'],
    originCountry: (json['origin_country'] as List<dynamic>? ?? [])
        .cast<String>(),
    originalLanguage: json['original_language'] ?? '',
    originalTitle: json['original_title'] ?? '',
    overview: json['overview'] ?? '',
    popularity: (json['popularity'] ?? 0).toDouble(),
    posterPath: json['poster_path'],
    productionCompanies: (json['production_companies'] as List<dynamic>? ?? [])
        .map((e) => ProductionCompany.fromJson(e))
        .toList(),
    productionCountries: (json['production_countries'] as List<dynamic>? ?? [])
        .map((e) => ProductionCountry.fromJson(e))
        .toList(),
    releaseDate: DateTime.tryParse(json['release_date']) ?? DateTime.now(),
    revenue: json['revenue'] ?? 0,
    runtime: json['runtime'],
    spokenLanguages: (json['spoken_languages'] as List<dynamic>? ?? [])
        .map((e) => SpokenLanguage.fromJson(e))
        .toList(),
    status: json['status'] ?? '',
    tagline: json['tagline'],
    title: json['title'] ?? '',
    video: json['video'] ?? false,
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    voteCount: json['vote_count'] ?? 0,
    images: json['images'] != null ? TmdbImages.fromJson(json['images']) : null,
    videos: json['videos'] != null ? TmdbVideos.fromJson(json['videos']) : null,
    credits: json['credits'] != null
        ? TmdbCredits.fromJson(json['credits'])
        : null,
    recommendations: json['recommendations'] != null
        ? TmdbMovieRecommendations.fromJson(json['recommendations'])
        : null,
  );
}
