import 'package:petal/models/trakt/ids.dart';
import 'package:petal/models/trakt/watch_stats.dart';

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
      ids: json['ids'] != null
          ? Ids.fromJson(json['ids'] as Map<String, dynamic>)
          : null,
      title: json['title'],
      completed: json['completed'],
      lastWatchedAt: json['last_watched_at'] != null
          ? DateTime.parse(json['last_watched_at'] as String)
          : null,
      stats: json['stats'] != null
          ? WatchStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
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
