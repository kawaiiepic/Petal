class TraktCommentActivities {
  final DateTime likedAt;
  final DateTime reactedAt;
  final DateTime blockedAt;

  TraktCommentActivities({
    required this.likedAt,
    required this.reactedAt,
    required this.blockedAt,
  });

  factory TraktCommentActivities.fromJson(Map<String, dynamic> json) {
    return TraktCommentActivities(
      likedAt: DateTime.parse(json['liked_at']),
      reactedAt: DateTime.parse(json['reacted_at']),
      blockedAt: DateTime.parse(json['blocked_at']),
    );
  }
}
