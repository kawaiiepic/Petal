import 'package:petal/models/watch_history/season_episode.dart';

class Season {
  final int number;
  final List<SeasonEpisode> episodes;

  Season({required this.number, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      number: (json['number'] as num).toInt(),
      episodes: (json['episodes'] as List<dynamic>? ?? [])
          .map((e) => SeasonEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
