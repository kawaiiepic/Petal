class TraktShowActivities {
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime favoritedAt;
  final DateTime commentedAt;
  final DateTime hiddenAt;
  final DateTime droppedAt;

  TraktShowActivities({
    required this.ratedAt,
    required this.watchlistedAt,
    required this.favoritedAt,
    required this.commentedAt,
    required this.hiddenAt,
    required this.droppedAt,
  });

  factory TraktShowActivities.fromJson(Map<String, dynamic> json) {
    return TraktShowActivities(
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      favoritedAt: DateTime.parse(json['favorited_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      hiddenAt: DateTime.parse(json['hidden_at']),
      droppedAt: DateTime.parse(json['dropped_at']),
    );
  }
}
