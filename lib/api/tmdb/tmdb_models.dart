import 'package:blssmpetal/api/tmdb/tmdb.dart';

class Images {
  List<Backdrops>? backdrops;
  int? id;
  List<Logos>? logos;
  List<Logos>? posters;
  List<Logos>? stills;

  Images({this.backdrops, this.id, this.logos, this.posters, this.stills});

  Images.fromJson(Map<String, dynamic> json) {
    if (json['backdrops'] != null) {
      backdrops = <Backdrops>[];
      json['backdrops'].forEach((v) {
        backdrops!.add(Backdrops.fromJson(v));
      });
    }
    id = json['id'];
    if (json['logos'] != null) {
      logos = <Logos>[];
      json['logos'].forEach((v) {
        logos!.add(Logos.fromJson(v));
      });
    }
    if (json['posters'] != null) {
      posters = <Logos>[];
      json['posters'].forEach((v) {
        posters!.add(Logos.fromJson(v));
      });
    }
    if (json['stills'] != null) {
      stills = <Logos>[];
      json['stills'].forEach((v) {
        stills!.add(Logos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (backdrops != null) {
      data['backdrops'] = backdrops!.map((v) => v.toJson()).toList();
    }
    data['id'] = id;
    if (logos != null) {
      data['logos'] = logos!.map((v) => v.toJson()).toList();
    }
    if (posters != null) {
      data['posters'] = posters!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Backdrops {
  double? aspectRatio;
  int? height;
  String? iso6391;
  String? filePath;
  double? voteAverage;
  int? voteCount;
  int? width;

  Backdrops({this.aspectRatio, this.height, this.iso6391, this.filePath, this.voteAverage, this.voteCount, this.width});

  Backdrops.fromJson(Map<String, dynamic> json) {
    aspectRatio = json['aspect_ratio'];
    height = json['height'];
    iso6391 = json['iso_639_1'];
    filePath = json['file_path'];
    voteAverage = json['vote_average'];
    voteCount = json['vote_count'];
    width = json['width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['aspect_ratio'] = aspectRatio;
    data['height'] = height;
    data['iso_639_1'] = iso6391;
    data['file_path'] = filePath;
    data['vote_average'] = voteAverage;
    data['vote_count'] = voteCount;
    data['width'] = width;
    return data;
  }
}

class Logos {
  double? aspectRatio;
  int? height;
  String? iso6391;
  String? filePath;
  double? voteAverage;
  int? voteCount;
  int? width;

  Logos({this.aspectRatio, this.height, this.iso6391, this.filePath, this.voteAverage, this.voteCount, this.width});

  Logos.fromJson(Map<String, dynamic> json) {
    aspectRatio = json['aspect_ratio'];
    height = json['height'];
    iso6391 = json['iso_639_1'];
    filePath = json['file_path'];
    voteAverage = json['vote_average'];
    voteCount = json['vote_count'];
    width = json['width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['aspect_ratio'] = aspectRatio;
    data['height'] = height;
    data['iso_639_1'] = iso6391;
    data['file_path'] = filePath;
    data['vote_average'] = voteAverage;
    data['vote_count'] = voteCount;
    data['width'] = width;
    return data;
  }
}

// models/tmdb_result.dart
class TmdbSearchResult {
  final List<TmdbMedia> movies;
  final List<TmdbMedia> tv;
  final List<TmdbMedia> people;

  TmdbSearchResult({required this.movies, required this.tv, required this.people});

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List? ?? []).map((e) => TmdbMedia.fromJson(e)).toList();

    return TmdbSearchResult(
      movies: (json['movie_results'] as List? ?? []).map((e) => TmdbMedia.fromJson(e)).toList(),
      tv: (json['tv_results'] as List? ?? []).map((e) => TmdbMedia.fromJson(e)).toList(),
      people: results.where((r) => r.mediaType == 'person').toList(),
    );
  }
}

class TmdbMedia {
  final int id;
  final String mediaType;
  final String title;
  final String posterPath;
  final String backdropPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;

  TmdbMedia({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
  });

  String? get posterUrl => '${TMDB.imageUrl}$posterPath';

  factory TmdbMedia.fromJson(Map<String, dynamic> json) {
    return TmdbMedia(
      id: json['id'],
      mediaType: json['media_type'] ?? '',
      title: json['title'] ?? json['name'] ?? '', // movie vs tv
      posterPath: "https://image.tmdb.org/t/p/original${json['poster_path']}",
      backdropPath: "https://image.tmdb.org/t/p/original${json['backdrop_path']}",
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'],
    );
  }
}

// models/episode.dart

class TmdbEpisode {
  final String airDate;
  final List<CrewMember> crew;
  final int episodeNumber;
  final List<GuestStar> guestStars;
  final String name;
  final String overview;
  final int id;
  final String productionCode;
  final int runtime;
  final int seasonNumber;
  final String? stillPath;
  final double voteAverage;
  final int voteCount;

  static const _imageBase = 'https://image.tmdb.org/t/p/w500';

  TmdbEpisode({
    required this.airDate,
    required this.crew,
    required this.episodeNumber,
    required this.guestStars,
    required this.name,
    required this.overview,
    required this.id,
    required this.productionCode,
    required this.runtime,
    required this.seasonNumber,
    required this.stillPath,
    required this.voteAverage,
    required this.voteCount,
  });

  String? get stillUrl => stillPath != null ? '$_imageBase$stillPath' : null;

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) {
    return TmdbEpisode(
      airDate: json['air_date'] ?? '',
      crew: (json['crew'] as List? ?? []).map((e) => CrewMember.fromJson(e)).toList(),
      episodeNumber: json['episode_number'],
      guestStars: (json['guest_stars'] as List? ?? []).map((e) => GuestStar.fromJson(e)).toList(),
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      id: json['id'],
      productionCode: json['production_code'] ?? '',
      runtime: json['runtime'] ?? 0,
      seasonNumber: json['season_number'],
      stillPath: json['still_path'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'air_date': airDate,
    'crew': crew.map((e) => e.toJson()).toList(),
    'episode_number': episodeNumber,
    'guest_stars': guestStars.map((e) => e.toJson()).toList(),
    'name': name,
    'overview': overview,
    'id': id,
    'production_code': productionCode,
    'runtime': runtime,
    'season_number': seasonNumber,
    'still_path': stillPath,
    'vote_average': voteAverage,
    'vote_count': voteCount,
  };
}

// ── Crew ─────────────────────────────────────────────

class CrewMember {
  final int id;
  final String name;
  final String job;
  final String department;
  final String creditId;
  final int gender;
  final double popularity;
  final String? profilePath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  CrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    required this.creditId,
    required this.gender,
    required this.popularity,
    required this.profilePath,
  });

  String? get profileUrl => profilePath != null ? '$_imageBase$profilePath' : null;

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id'],
      name: json['name'] ?? '',
      job: json['job'] ?? '',
      department: json['department'] ?? '',
      creditId: json['credit_id'] ?? '',
      gender: json['gender'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      profilePath: json['profile_path'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'job': job,
    'department': department,
    'credit_id': creditId,
    'gender': gender,
    'popularity': popularity,
    'profile_path': profilePath,
  };
}

// ── Guest Star ────────────────────────────────────────

class GuestStar {
  final int id;
  final String name;
  final String character;
  final String creditId;
  final int order;
  final int gender;
  final double popularity;
  final String? profilePath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  GuestStar({
    required this.id,
    required this.name,
    required this.character,
    required this.creditId,
    required this.order,
    required this.gender,
    required this.popularity,
    required this.profilePath,
  });

  String? get profileUrl => profilePath != null ? '$_imageBase$profilePath' : null;

  factory GuestStar.fromJson(Map<String, dynamic> json) {
    return GuestStar(
      id: json['id'],
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      creditId: json['credit_id'] ?? '',
      order: json['order'] ?? 0,
      gender: json['gender'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      profilePath: json['profile_path'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'character': character,
    'credit_id': creditId,
    'order': order,
    'gender': gender,
    'popularity': popularity,
    'profile_path': profilePath,
  };
}

// models/tv_show.dart

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
    required this.imdbId,
  });

  String? get posterUrl => posterPath != null ? '$_imageBase$posterPath' : null;
  String? get backdropUrl => backdropPath != null ? '$_backdropBase$backdropPath' : null;

  List<SeasonSummary> get mainSeasons => seasons.where((s) => s.seasonNumber > 0).toList();

  factory TmdbShow.fromJson(Map<String, dynamic> json) => TmdbShow(
    adult: json['adult'] ?? false,
    backdropPath: json['backdrop_path'],
    createdBy: (json['created_by'] as List? ?? []).map((e) => CreatedBy.fromJson(e)).toList(),
    episodeRunTime: (json['episode_run_time'] as List? ?? []).map((e) => e as int).toList(),
    firstAirDate: json['first_air_date'] ?? '',
    lastAirDate: json['last_air_date'] ?? '',
    genres: (json['genres'] as List? ?? []).map((e) => Genre.fromJson(e)).toList(),
    homepage: json['homepage'] ?? '',
    id: json['id'],
    inProduction: json['in_production'] ?? false,
    languages: (json['languages'] as List? ?? []).map((e) => e as String).toList(),
    lastEpisodeToAir: json['last_episode_to_air'] != null ? EpisodeSummary.fromJson(json['last_episode_to_air']) : null,
    name: json['name'] ?? '',
    originalName: json['original_name'] ?? '',
    overview: json['overview'] ?? '',
    popularity: (json['popularity'] ?? 0).toDouble(),
    posterPath: json['poster_path'],
    networks: (json['networks'] as List? ?? []).map((e) => Network.fromJson(e)).toList(),
    numberOfEpisodes: json['number_of_episodes'] ?? 0,
    numberOfSeasons: json['number_of_seasons'] ?? 0,
    originCountry: (json['origin_country'] as List? ?? []).map((e) => e as String).toList(),
    seasons: (json['seasons'] as List? ?? []).map((e) => SeasonSummary.fromJson(e)).toList(),
    status: json['status'] ?? '',
    tagline: json['tagline'] ?? '',
    type: json['type'] ?? '',
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    voteCount: json['vote_count'] ?? 0,
    images: json['images'] != null ? TmdbImages.fromJson(json['images']) : null,
    imdbId: json['external_ids']?['imdb_id'],
  );
}

// ── Created By ────────────────────────────────────────

class CreatedBy {
  final int id;
  final String creditId;
  final String name;
  final int gender;
  final String? profilePath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  CreatedBy({required this.id, required this.creditId, required this.name, required this.gender, required this.profilePath});

  String? get profileUrl => profilePath != null ? '$_imageBase$profilePath' : null;

  factory CreatedBy.fromJson(Map<String, dynamic> json) =>
      CreatedBy(id: json['id'], creditId: json['credit_id'] ?? '', name: json['name'] ?? '', gender: json['gender'] ?? 0, profilePath: json['profile_path']);
}

// ── Genre ─────────────────────────────────────────────

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(id: json['id'], name: json['name'] ?? '');
}

// ── Network ───────────────────────────────────────────

class Network {
  final int id;
  final String name;
  final String? logoPath;
  final String originCountry;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  Network({required this.id, required this.name, required this.logoPath, required this.originCountry});

  String? get logoUrl => logoPath != null ? '$_imageBase$logoPath' : null;

  factory Network.fromJson(Map<String, dynamic> json) =>
      Network(id: json['id'], name: json['name'] ?? '', logoPath: json['logo_path'], originCountry: json['origin_country'] ?? '');
}

// ── Season Summary (from show response) ───────────────

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

// ── Episode Summary (last_episode_to_air) ─────────────

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

class TmdbImages {
  final List<TmdbImage> backdrops;
  final List<TmdbImage> posters;
  final List<TmdbImage> logos;

  TmdbImages({required this.backdrops, required this.posters, required this.logos});

  factory TmdbImages.fromJson(Map<String, dynamic> json) => TmdbImages(
    backdrops: (json['backdrops'] as List? ?? []).map((e) => TmdbImage.fromJson(e)).toList(),
    posters: (json['posters'] as List? ?? []).map((e) => TmdbImage.fromJson(e)).toList(),
    logos: (json['logos'] as List? ?? []).map((e) => TmdbImage.fromJson(e)).toList(),
  );
}

class TmdbImage {
  final String filePath;
  final int width;
  final int height;
  final double voteAverage;
  final String? iso6391; // language, null = no language (best for logos)

  static const _base = 'https://image.tmdb.org/t/p/original';

  TmdbImage({required this.filePath, required this.width, required this.height, required this.voteAverage, required this.iso6391});

  String get url => '$_base$filePath';

  factory TmdbImage.fromJson(Map<String, dynamic> json) => TmdbImage(
    filePath: json['file_path'] ?? '',
    width: json['width'] ?? 0,
    height: json['height'] ?? 0,
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    iso6391: json['iso_639_1'],
  );
}

// movie_model.dart

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
  final String releaseDate;
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
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) => TmdbMovie(
    adult: json['adult'] ?? false,
    backdropPath: json['backdrop_path'],
    belongsToCollection: json['belongs_to_collection'] != null ? Collection.fromJson(json['belongs_to_collection']) : null,
    budget: json['budget'] ?? 0,
    genres: (json['genres'] as List<dynamic>? ?? []).map((e) => Genre.fromJson(e)).toList(),
    homepage: json['homepage'],
    id: json['id'] ?? 0,
    imdbId: json['imdb_id'],
    originCountry: (json['origin_country'] as List<dynamic>? ?? []).cast<String>(),
    originalLanguage: json['original_language'] ?? '',
    originalTitle: json['original_title'] ?? '',
    overview: json['overview'] ?? '',
    popularity: (json['popularity'] ?? 0).toDouble(),
    posterPath: json['poster_path'],
    productionCompanies: (json['production_companies'] as List<dynamic>? ?? []).map((e) => ProductionCompany.fromJson(e)).toList(),
    productionCountries: (json['production_countries'] as List<dynamic>? ?? []).map((e) => ProductionCountry.fromJson(e)).toList(),
    releaseDate: json['release_date'] ?? '',
    revenue: json['revenue'] ?? 0,
    runtime: json['runtime'],
    spokenLanguages: (json['spoken_languages'] as List<dynamic>? ?? []).map((e) => SpokenLanguage.fromJson(e)).toList(),
    status: json['status'] ?? '',
    tagline: json['tagline'],
    title: json['title'] ?? '',
    video: json['video'] ?? false,
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    voteCount: json['vote_count'] ?? 0,
    images: json['images'] != null ? TmdbImages.fromJson(json['images']) : null,
  );
}

// Nested models

class Collection {
  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;

  Collection({required this.id, required this.name, this.posterPath, this.backdropPath});

  factory Collection.fromJson(Map<String, dynamic> json) =>
      Collection(id: json['id'] ?? 0, name: json['name'] ?? '', posterPath: json['poster_path'], backdropPath: json['backdrop_path']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'poster_path': posterPath, 'backdrop_path': backdropPath};
}

class ProductionCompany {
  final int id;
  final String name;
  final String? logoPath;
  final String? originCountry;

  ProductionCompany({required this.id, required this.name, this.logoPath, this.originCountry});

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      ProductionCompany(id: json['id'] ?? 0, name: json['name'] ?? '', logoPath: json['logo_path'], originCountry: json['origin_country']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'logo_path': logoPath, 'origin_country': originCountry};
}

class ProductionCountry {
  final String iso3166_1;
  final String name;

  ProductionCountry({required this.iso3166_1, required this.name});

  factory ProductionCountry.fromJson(Map<String, dynamic> json) => ProductionCountry(iso3166_1: json['iso_3166_1'] ?? '', name: json['name'] ?? '');

  Map<String, dynamic> toJson() => {'iso_3166_1': iso3166_1, 'name': name};
}

class SpokenLanguage {
  final String englishName;
  final String iso639_1;
  final String name;

  SpokenLanguage({required this.englishName, required this.iso639_1, required this.name});

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) =>
      SpokenLanguage(englishName: json['english_name'] ?? '', iso639_1: json['iso_639_1'] ?? '', name: json['name'] ?? '');

  Map<String, dynamic> toJson() => {'english_name': englishName, 'iso_639_1': iso639_1, 'name': name};
}

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
    episodes: (json['episodes'] as List<dynamic>).map((e) => TmdbEpisode.fromJson(e as Map<String, dynamic>)).toList(),
    name: json['name'] as String,
    overview: json['overview'] as String?,
    posterPath: json['poster_path'] as String?,
    seasonNumber: json['season_number'] as int,
    voteAverage: (json['vote_average'] as num).toDouble(),
  );
}

class TmdbCrewMember {
  final int id;
  final String name;
  final String job;
  final String department;
  final String creditId;
  final String? profilePath;
  final double popularity;

  const TmdbCrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    required this.creditId,
    this.profilePath,
    required this.popularity,
  });

  factory TmdbCrewMember.fromJson(Map<String, dynamic> json) => TmdbCrewMember(
    id: json['id'] as int,
    name: json['name'] as String,
    job: json['job'] as String,
    department: json['department'] as String,
    creditId: json['credit_id'] as String,
    profilePath: json['profile_path'] as String?,
    popularity: (json['popularity'] as num).toDouble(),
  );
}

class TmdbGuestStar {
  final int id;
  final String name;
  final String character;
  final String creditId;
  final int order;
  final String? profilePath;
  final double popularity;

  const TmdbGuestStar({
    required this.id,
    required this.name,
    required this.character,
    required this.creditId,
    required this.order,
    this.profilePath,
    required this.popularity,
  });

  factory TmdbGuestStar.fromJson(Map<String, dynamic> json) => TmdbGuestStar(
    id: json['id'] as int,
    name: json['name'] as String,
    character: json['character'] as String,
    creditId: json['credit_id'] as String,
    order: json['order'] as int,
    profilePath: json['profile_path'] as String?,
    popularity: (json['popularity'] as num).toDouble(),
  );
}
