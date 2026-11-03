import 'package:petal/models/trakt/ids.dart';
import 'package:petal/models/trakt/trakt_episode.dart';
import 'package:petal/models/trakt/trakt_season_images.dart';

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
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      votes: json['votes'] as int?,
      episodeCount: json['episode_count'] as int?,
      airedEpisodes: json['aired_episodes'] as int?,
      firstAired: json['first_aired'] as String?,
      updatedAt: json['updated_at'] as String?,
      ids: Ids.fromJson(json['ids'] as Map<String, dynamic>),
      images: TraktSeasonImages.fromJson(
        json['images'] as Map<String, dynamic>,
      ),
      episodes: json['episodes'] != null
          ? (json['episodes'] as List<dynamic>)
                .map((e) => TraktEpisode.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
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
