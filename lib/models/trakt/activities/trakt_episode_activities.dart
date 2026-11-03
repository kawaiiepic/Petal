class TraktEpisodeActivities {
  final DateTime watchedAt;
  final DateTime collectedAt;
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime commentedAt;
  final DateTime pausedAt;

  TraktEpisodeActivities({
    required this.watchedAt,
    required this.collectedAt,
    required this.ratedAt,
    required this.watchlistedAt,
    required this.commentedAt,
    required this.pausedAt,
  });

  factory TraktEpisodeActivities.fromJson(Map<String, dynamic> json) {
    return TraktEpisodeActivities(
      watchedAt: DateTime.parse(json['watched_at']),
      collectedAt: DateTime.parse(json['collected_at']),
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      pausedAt: DateTime.parse(json['paused_at']),
    );
  }
}
