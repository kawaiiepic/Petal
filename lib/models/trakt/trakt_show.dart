import 'package:petal/models/trakt/show.dart';

class TraktShow {
  final int plays;
  final String lastWatchedAt;
  final String lastUpdatedAt;
  final Show show;

  TraktShow({
    required this.plays,
    required this.lastWatchedAt,
    required this.lastUpdatedAt,
    required this.show,
  });

  factory TraktShow.fromJson(Map<String, dynamic> json) {
    return TraktShow(
      plays: json['plays'],
      lastWatchedAt: json['last_watched_at'],
      lastUpdatedAt: json['last_updated_at'],
      show: Show.fromJson(json['show']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plays': plays,
      'last_watched_at': lastWatchedAt,
      'last_updated_at': lastUpdatedAt,
      'show': show.toJson(),
    };
  }
}
