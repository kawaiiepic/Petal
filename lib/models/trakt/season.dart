import 'package:petal/models/trakt/season_episode.dart';
import 'package:petal/models/trakt/watch_stats.dart';

class Season {
  final int number;
  final String? title;
  final int? aired;
  final int? completed;
  final WatchStats? stats;
  final List<SeasonEpisode> episodes;

  Season({
    required this.number,
    required this.title,
    required this.aired,
    required this.completed,
    required this.stats,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      number: json['number'],
      title: json['title'],
      aired: json['aired'],
      completed: json['completed'],
      stats: json['stats'] != null
          ? WatchStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => SeasonEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
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
