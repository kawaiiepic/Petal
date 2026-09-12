class WatchSession {
  final String profileId;
  final int tmdbId;
  final String mediaType; // 'movie' | 'show'
  final String title;
  final String? episodeTitle;
  final int? season;
  final int? episode;
  final int position;
  final int duration;
  final int lastSeen;

  const WatchSession({
    required this.profileId,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.episodeTitle,
    this.season,
    this.episode,
    required this.position,
    required this.duration,
    required this.lastSeen,
  });

  factory WatchSession.fromJson(Map<String, dynamic> json) {
    return WatchSession(
      profileId: json['profileId'] as String,
      tmdbId: json['tmdbId'] as int,
      mediaType: json['mediaType'] as String,
      title: json['title'] as String,
      episodeTitle: json['episodeTitle'] as String?,
      season: json['season'] as int?,
      episode: json['episode'] as int?,
      position: json['position'] as int,
      duration: json['duration'] as int,
      lastSeen: json['lastSeen'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'tmdbId': tmdbId,
    'mediaType': mediaType,
    'title': title,
    'episodeTitle': episodeTitle,
    'season': season,
    'episode': episode,
    'position': position,
    'duration': duration,
    'lastSeen': lastSeen,
  };

  double get progress => duration > 0 ? position / duration : 0.0;

  bool get isShow => mediaType == 'show';
}
