import 'package:petal/models/trakt/ids.dart';

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
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      genres: json['genres'] != null ? List<String>.from(json['genres']) : null,
      subgenres: json['subgenres'] != null
          ? List<String>.from(json['subgenres'])
          : null,
      availableTranslations: json['available_translations'] != null
          ? List<String>.from(json['available_translations'])
          : null,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
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
