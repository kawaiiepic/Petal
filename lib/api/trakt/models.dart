import 'dart:convert';

class TraktShow {
  final int plays;
  final String lastWatchedAt;
  final String lastUpdatedAt;
  final Show show;

  TraktShow({required this.plays, required this.lastWatchedAt, required this.lastUpdatedAt, required this.show});

  factory TraktShow.fromJson(Map<String, dynamic> json) {
    return TraktShow(plays: json['plays'], lastWatchedAt: json['last_watched_at'], lastUpdatedAt: json['last_updated_at'], show: Show.fromJson(json['show']));
  }

  Map<String, dynamic> toJson() {
    return {'plays': plays, 'last_watched_at': lastWatchedAt, 'last_updated_at': lastUpdatedAt, 'show': show.toJson()};
  }
}

class Show {
  final String title;
  final int year;
  final Ids ids;
  final String? overview;
  final String? tagline;
  final String? trailer;
  final String? homepage;
  final String? network;
  final String? country;
  final String? language;
  final String? status;
  final String? certification;
  final String? firstAired;
  final int? runtime;
  final int? airedEpisodes;
  final int? votes;
  final int? commentCount;
  final double? rating;
  final List<String>? genres;
  final List<String>? subgenres;
  final List<String>? availableTranslations;
  final List<String>? languages;

  Show({
    required this.title,
    required this.year,
    required this.ids,
    required this.overview,
    this.tagline,
    this.trailer,
    this.homepage,
    this.network,
    this.country,
    this.language,
    this.status,
    this.certification,
    this.firstAired,
    this.runtime,
    this.airedEpisodes,
    this.votes,
    this.commentCount,
    this.rating,
    this.genres,
    this.subgenres,
    this.availableTranslations,
    this.languages,
  });

  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      title: json['title'] as String,
      year: json['year'] as int,
      ids: Ids.fromJson(json['ids'] as Map<String, dynamic>),
      overview: json['overview'] as String? ?? '',
      tagline: json['tagline'] as String?,
      trailer: json['trailer'] as String?,
      homepage: json['homepage'] as String?,
      network: json['network'] as String?,
      country: json['country'] as String?,
      language: json['language'] as String?,
      status: json['status'] as String?,
      certification: json['certification'] as String?,
      firstAired: json['first_aired'] as String?,
      runtime: json['runtime'] as int?,
      airedEpisodes: json['aired_episodes'] as int?,
      votes: json['votes'] as int?,
      commentCount: json['comment_count'] as int?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      genres: json['genres'] != null ? List<String>.from(json['genres']) : null,
      subgenres: json['subgenres'] != null ? List<String>.from(json['subgenres']) : null,
      availableTranslations: json['available_translations'] != null ? List<String>.from(json['available_translations']) : null,
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'year': year,
    'ids': ids.toJson(),
    'overview': overview,
    'tagline': tagline,
    'trailer': trailer,
    'homepage': homepage,
    'network': network,
    'country': country,
    'language': language,
    'status': status,
    'certification': certification,
    'first_aired': firstAired,
    'runtime': runtime,
    'aired_episodes': airedEpisodes,
    'votes': votes,
    'comment_count': commentCount,
    'rating': rating,
    'genres': genres,
    'subgenres': subgenres,
    'available_translations': availableTranslations,
    'languages': languages,
  };
}

class Ids {
  final int trakt;
  final String? slug;
  final int? tvdb;
  final String? imdb;
  final int? tmdb;

  Ids({required this.trakt, required this.slug, this.tvdb, this.imdb, this.tmdb});

  factory Ids.fromJson(Map<String, dynamic> json) {
    return Ids(trakt: json['trakt'], slug: json['slug'], tvdb: json['tvdb'], imdb: json['imdb'], tmdb: json['tmdb']);
  }

  Map<String, dynamic> toJson() {
    return {'trakt': trakt, 'slug': slug, 'tvdb': tvdb, 'imdb': imdb, 'tmdb': tmdb};
  }
}

class TraktShowProgress {
  final int aired;
  final int completed;
  final DateTime? lastWatchedAt;
  final DateTime? resetAt;
  final TraktEpisode? lastEpisode;
  final TraktEpisode? nextEpisode;
  final WatchStats? stats;
  final List<Season> seasons;
  final List<dynamic> hiddenSeasons;

  TraktShowProgress({
    required this.aired,
    required this.completed,
    this.lastWatchedAt,
    this.resetAt,
    this.lastEpisode,
    this.nextEpisode,
    required this.stats,
    required this.seasons,
    required this.hiddenSeasons,
  });

  factory TraktShowProgress.fromJson(Map<String, dynamic> json) {
    return TraktShowProgress(
      aired: json['aired'] as int,
      completed: json['completed'] as int,
      lastWatchedAt: json['last_watched_at'] != null ? DateTime.parse(json['last_watched_at'] as String) : null,
      resetAt: json['reset_at'] != null ? DateTime.parse(json['reset_at'] as String) : null,
      lastEpisode: json['last_episode'] != null ? TraktEpisode.fromJson(json['last_episode'] as Map<String, dynamic>) : null,
      nextEpisode: json['next_episode'] != null ? TraktEpisode.fromJson(json['next_episode'] as Map<String, dynamic>) : null,
      stats: json['stats'] != null ? WatchStats.fromJson(json['stats'] as Map<String, dynamic>) : null,
      seasons: (json['seasons'] as List<dynamic>).map((e) => Season.fromJson(e as Map<String, dynamic>)).toList(),
      hiddenSeasons: json['hidden_seasons'] as List<dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'aired': aired,
    'completed': completed,
    'last_watched_at': lastWatchedAt?.toIso8601String(),
    'reset_at': resetAt?.toIso8601String(),
    'last_episode': lastEpisode?.toJson(),
    'next_episode': nextEpisode?.toJson(),
    'stats': stats?.toJson(),
    'seasons': seasons.map((e) => e.toJson()).toList(),
    'hidden_seasons': hiddenSeasons,
  };

  static TraktShowProgress fromJsonString(String source) => TraktShowProgress.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

class TraktEpisode {
  final int season;
  final int number;
  final String? title;
  final String? originalTitle;
  final String? overview;
  final String? episodeType;
  final String? firstAired;
  final String? updatedAt;
  final double? rating;
  final int? votes;
  final int? runtime;
  final int? commentCount;
  final bool? afterCredits;
  final bool? duringCredits;
  final int? numberAbs;
  final Ids ids;
  final TraktEpisodeImages images;
  final List<String> availableTranslations;

  TraktEpisode({
    required this.season,
    required this.number,
    this.title,
    this.originalTitle,
    this.overview,
    this.episodeType,
    this.firstAired,
    this.updatedAt,
    this.rating,
    this.votes,
    this.runtime,
    this.commentCount,
    this.afterCredits,
    this.duringCredits,
    this.numberAbs,
    required this.ids,
    required this.images,
    required this.availableTranslations,
  });

  factory TraktEpisode.fromJson(Map<String, dynamic> json) {
    return TraktEpisode(
      season: json['season'] as int,
      number: json['number'] as int,
      title: json['title'] as String?,
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      episodeType: json['episode_type'] as String?,
      firstAired: json['first_aired'] as String?,
      updatedAt: json['updated_at'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      votes: json['votes'] as int?,
      runtime: json['runtime'] as int?,
      commentCount: json['comment_count'] as int?,
      afterCredits: json['after_credits'] as bool?,
      duringCredits: json['during_credits'] as bool?,
      numberAbs: json['number_abs'] as int?,
      ids: Ids.fromJson(json['ids'] as Map<String, dynamic>),
      images: TraktEpisodeImages.fromJson(json['images'] as Map<String, dynamic>),
      availableTranslations: json['available_translations'] != null ? List<String>.from(json['available_translations']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'season': season,
    'number': number,
    'title': title,
    'original_title': originalTitle,
    'overview': overview,
    'episode_type': episodeType,
    'first_aired': firstAired,
    'updated_at': updatedAt,
    'rating': rating,
    'votes': votes,
    'runtime': runtime,
    'comment_count': commentCount,
    'after_credits': afterCredits,
    'during_credits': duringCredits,
    'number_abs': numberAbs,
    'ids': ids.toJson(),
    'images': images.toJson(),
    'available_translations': availableTranslations,
  };
}

class TraktEpisodeImages {
  final List<String> screenshot;

  TraktEpisodeImages({required this.screenshot});

  factory TraktEpisodeImages.fromJson(Map<String, dynamic> json) {
    return TraktEpisodeImages(screenshot: json['screenshot'] != null ? List<String>.from(json['screenshot']) : []);
  }

  Map<String, dynamic> toJson() => {'screenshot': screenshot};
}

// Plex IDs
class PlexIds {
  final String guid;

  PlexIds({required this.guid});

  factory PlexIds.fromJson(Map<String, dynamic> json) => PlexIds(guid: json['guid'] as String);

  Map<String, dynamic> toJson() => {'guid': guid};
}

// Episode Images
class EpisodeImages {
  final List<String> screenshot;

  EpisodeImages({required this.screenshot});

  factory EpisodeImages.fromJson(Map<String, dynamic> json) {
    return EpisodeImages(screenshot: List<String>.from(json['screenshot'] as List<dynamic>));
  }

  Map<String, dynamic> toJson() => {'screenshot': screenshot};
}

// Watch stats (used at show level, season level, and episode level)
class WatchStats {
  final int? playCount;
  final int? minutesWatched;
  final int? minutesLeft;

  WatchStats({this.playCount, this.minutesWatched, this.minutesLeft});

  factory WatchStats.fromJson(Map<String, dynamic> json) {
    return WatchStats(playCount: json['play_count'] as int?, minutesWatched: json['minutes_watched'] as int?, minutesLeft: json['minutes_left'] as int?);
  }

  Map<String, dynamic> toJson() => {
    if (playCount != null) 'play_count': playCount,
    if (minutesWatched != null) 'minutes_watched': minutesWatched,
    if (minutesLeft != null) 'minutes_left': minutesLeft,
  };
}

// Season model
class Season {
  final int number;
  final String? title;
  final int? aired;
  final int? completed;
  final WatchStats? stats;
  final List<SeasonEpisode> episodes;

  Season({required this.number, required this.title, required this.aired, required this.completed, required this.stats, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      number: json['number'],
      title: json['title'],
      aired: json['aired'],
      completed: json['completed'],
      stats: json['stats'] != null ? WatchStats.fromJson(json['stats'] as Map<String, dynamic>) : null,
      episodes: (json['episodes'] as List<dynamic>).map((e) => SeasonEpisode.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'aired': aired,
    'completed': completed,
    'stats': stats?.toJson(),
    'episodes': episodes.map((e) => e.toJson()).toList(),
  };
}

// Season Episode model
class SeasonEpisode {
  final int? season;
  final int number;
  final Ids? ids;
  final String? title;
  final bool? completed;
  final DateTime? lastWatchedAt;
  final WatchStats? stats;

  SeasonEpisode({
    required this.season,
    required this.number,
    required this.ids,
    required this.title,
    required this.completed,
    this.lastWatchedAt,
    required this.stats,
  });

  factory SeasonEpisode.fromJson(Map<String, dynamic> json) {
    // print("Title: ${json["title"]} IDS: ${json["ids"]}");
    return SeasonEpisode(
      season: json['season'],
      number: json['number'],
      ids: json['ids'] != null ? Ids.fromJson(json['ids'] as Map<String, dynamic>) : null,
      title: json['title'],
      completed: json['completed'],
      lastWatchedAt: json['last_watched_at'] != null ? DateTime.parse(json['last_watched_at'] as String) : null,
      stats: json['stats'] != null ? WatchStats.fromJson(json['stats'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'season': season,
    'number': number,
    'ids': ids?.toJson(),
    'title': title,
    'completed': completed,
    'last_watched_at': lastWatchedAt?.toIso8601String(),
    'stats': stats?.toJson(),
  };
}

class TraktSeason {
  final int number;
  final String? title;
  final String? originalTitle;
  final String? overview;
  final String? network;
  final double? rating;
  final int? votes;
  final int? episodeCount;
  final int? airedEpisodes;
  final String? firstAired;
  final String? updatedAt;
  final Ids ids;
  final TraktSeasonImages images;
  final List<TraktEpisode> episodes;

  TraktSeason({
    required this.number,
    this.title,
    this.originalTitle,
    this.overview,
    this.network,
    this.rating,
    this.votes,
    this.episodeCount,
    this.airedEpisodes,
    this.firstAired,
    this.updatedAt,
    required this.ids,
    required this.images,
    required this.episodes,
  });

  factory TraktSeason.fromJson(Map<String, dynamic> json) {
    return TraktSeason(
      number: json['number'] as int,
      title: json['title'] as String?,
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      network: json['network'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      votes: json['votes'] as int?,
      episodeCount: json['episode_count'] as int?,
      airedEpisodes: json['aired_episodes'] as int?,
      firstAired: json['first_aired'] as String?,
      updatedAt: json['updated_at'] as String?,
      ids: Ids.fromJson(json['ids'] as Map<String, dynamic>),
      images: TraktSeasonImages.fromJson(json['images'] as Map<String, dynamic>),
      episodes: json['episodes'] != null ? (json['episodes'] as List<dynamic>).map((e) => TraktEpisode.fromJson(e as Map<String, dynamic>)).toList() : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'original_title': originalTitle,
    'overview': overview,
    'network': network,
    'rating': rating,
    'votes': votes,
    'episode_count': episodeCount,
    'aired_episodes': airedEpisodes,
    'first_aired': firstAired,
    'updated_at': updatedAt,
    'ids': ids.toJson(),
    'images': images.toJson(),
    'episodes': episodes.map((e) => e.toJson()).toList(),
  };
}

class TraktSeasonImages {
  final List<String> thumb;
  final List<String> poster;

  TraktSeasonImages({required this.thumb, required this.poster});

  factory TraktSeasonImages.fromJson(Map<String, dynamic> json) {
    return TraktSeasonImages(
      thumb: json['thumb'] != null ? List<String>.from(json['thumb']) : [],
      poster: json['poster'] != null ? List<String>.from(json['poster']) : [],
    );
  }

  Map<String, dynamic> toJson() => {'thumb': thumb, 'poster': poster};
}

class Search {
  final String type;
  final double? score;
  final Movie? movie;
  final Show? show;

  Search({required this.type, required this.score, this.movie, this.show});

  factory Search.fromJson(Map<String, dynamic> json) {
    return Search(
      type: json['type'],
      score: (json['score'] as num?)?.toDouble(),
      movie: json['movie'] != null ? Movie.fromJson(json['movie']) : null,
      show: json['show'] != null ? Show.fromJson(json['show']) : null,
    );
  }
}

class Movie {
  final String title;
  final int year;
  final Ids ids;
  final int? runtime; // runtime in minutes
  final double? rating; // rating, e.g., 8.5
  final String? overview; // description/summary
  final List<String>? genres; // list of genres
  final String? certification; // e.g., PG-13, R
  final MovieImages? images; // posters/screenshots

  Movie({required this.title, required this.year, required this.ids, this.runtime, this.rating, this.overview, this.genres, this.certification, this.images});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] ?? '',
      year: json['year'] ?? 0,
      ids: Ids.fromJson(json['ids']),
      runtime: json['runtime'],
      rating: (json['rating'] != null) ? (json['rating'] as num).toDouble() : null,
      overview: json['overview'],
      genres: (json['genres'] != null) ? List<String>.from(json['genres']) : null,
      certification: json['certification'],
      images: json['images'] != null ? MovieImages.fromJson(json['images']) : null,
    );
  }
}

class MovieImages {
  final List<String>? logo;
  final List<String>? poster;
  final List<String>? banner;
  final List<String>? fanart;
  final List<String>? thumb;
  final List<String>? clearart;

  MovieImages({this.logo, this.poster, this.banner, this.fanart, this.thumb, this.clearart});

  factory MovieImages.fromJson(Map<String, dynamic> json) {
    return MovieImages(
      logo: json['logo'] != null ? List<String>.from(json['logo']) : null,
      poster: json['poster'] != null ? List<String>.from(json['poster']) : null,
      banner: json['banner'] != null ? List<String>.from(json['banner']) : null,
      fanart: json['fanart'] != null ? List<String>.from(json['fanart']) : null,
      thumb: json['thumb'] != null ? List<String>.from(json['thumb']) : null,
      clearart: json['clearart'] != null ? List<String>.from(json['clearart']) : null,
    );
  }
}
