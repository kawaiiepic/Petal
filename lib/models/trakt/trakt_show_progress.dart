import 'dart:convert';

import 'package:petal/models/trakt/season.dart';
import 'package:petal/models/trakt/trakt_episode.dart';
import 'package:petal/models/trakt/watch_stats.dart';

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
      lastWatchedAt: json['last_watched_at'] != null
          ? DateTime.parse(json['last_watched_at'] as String)
          : null,
      resetAt: json['reset_at'] != null
          ? DateTime.parse(json['reset_at'] as String)
          : null,
      lastEpisode: json['last_episode'] != null
          ? TraktEpisode.fromJson(json['last_episode'] as Map<String, dynamic>)
          : null,
      nextEpisode: json['next_episode'] != null
          ? TraktEpisode.fromJson(json['next_episode'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? WatchStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      seasons: (json['seasons'] as List<dynamic>)
          .map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
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

  static TraktShowProgress fromJsonString(String source) =>
      TraktShowProgress.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
