import 'package:petal/models/trakt/ids.dart';
import 'package:petal/models/trakt/trakt_episode_images.dart';

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
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      votes: json['votes'] as int?,
      runtime: json['runtime'] as int?,
      commentCount: json['comment_count'] as int?,
      afterCredits: json['after_credits'] as bool?,
      duringCredits: json['during_credits'] as bool?,
      numberAbs: json['number_abs'] as int?,
      ids: Ids.fromJson(json['ids'] as Map<String, dynamic>),
      images: TraktEpisodeImages.fromJson(
        json['images'] as Map<String, dynamic>,
      ),
      availableTranslations: json['available_translations'] != null
          ? List<String>.from(json['available_translations'])
          : [],
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
