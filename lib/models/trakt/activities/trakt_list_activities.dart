class TraktListActivities {
  final DateTime likedAt;
  final DateTime reactedAt;
  final DateTime updatedAt;
  final DateTime commentedAt;

  TraktListActivities({
    required this.likedAt,
    required this.reactedAt,
    required this.updatedAt,
    required this.commentedAt,
  });

  factory TraktListActivities.fromJson(Map<String, dynamic> json) {
    return TraktListActivities(
      likedAt: DateTime.parse(json['liked_at']),
      reactedAt: DateTime.parse(json['reacted_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      commentedAt: DateTime.parse(json['commented_at']),
    );
  }
}
