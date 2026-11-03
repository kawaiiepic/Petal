import 'package:petal/models/tmdb/crew_member.dart';
import 'package:petal/models/tmdb/guest_star.dart';

class TmdbEpisode {
  final DateTime? airDate;
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
      airDate: json['air_date'] != null
          ? DateTime.parse(json['air_date'])
          : null,
      crew: (json['crew'] as List? ?? [])
          .map((e) => CrewMember.fromJson(e))
          .toList(),
      episodeNumber: json['episode_number'],
      guestStars: (json['guest_stars'] as List? ?? [])
          .map((e) => GuestStar.fromJson(e))
          .toList(),
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
