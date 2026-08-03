class MediaState {
  final int tmdbId;
  final String mediaType;
  final int season;
  final int episode;
  final double completion;
  final String? nextEpisode;

  MediaState({required this.tmdbId, required this.mediaType, required this.season, required this.episode, required this.completion, this.nextEpisode});

  factory MediaState.fromJson(Map<String, dynamic> json) {
    return MediaState(
      tmdbId: json['tmdb_id'],
      mediaType: json['media_type'],
      season: json['season'],
      episode: json['episode'],
      completion: json['completion'],
      nextEpisode: json['next_episode'],
    );
  }
}
