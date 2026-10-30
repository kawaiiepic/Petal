class TraktMovieActivities {
  final DateTime watchedAt;
  final DateTime collectedAt;
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime favoritedAt;
  final DateTime commentedAt;
  final DateTime pausedAt;
  final DateTime hiddenAt;

  TraktMovieActivities({
    required this.watchedAt,
    required this.collectedAt,
    required this.ratedAt,
    required this.watchlistedAt,
    required this.favoritedAt,
    required this.commentedAt,
    required this.pausedAt,
    required this.hiddenAt,
  });

  factory TraktMovieActivities.fromJson(Map<String, dynamic> json) {
    return TraktMovieActivities(
      watchedAt: DateTime.parse(json['watched_at']),
      collectedAt: DateTime.parse(json['collected_at']),
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      favoritedAt: DateTime.parse(json['favorited_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      pausedAt: DateTime.parse(json['paused_at']),
      hiddenAt: DateTime.parse(json['hidden_at']),
    );
  }
}
