class TraktSeasonActivities {
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime commentedAt;
  final DateTime hiddenAt;

  TraktSeasonActivities({
    required this.ratedAt,
    required this.watchlistedAt,
    required this.commentedAt,
    required this.hiddenAt,
  });

  factory TraktSeasonActivities.fromJson(Map<String, dynamic> json) {
    return TraktSeasonActivities(
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      hiddenAt: DateTime.parse(json['hidden_at']),
    );
  }
}
