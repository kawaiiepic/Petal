class TraktAccountActivities {
  final DateTime settingsAt;
  final DateTime followedAt;
  final DateTime followingAt;
  final DateTime pendingAt;
  final DateTime requestedAt;

  TraktAccountActivities({
    required this.settingsAt,
    required this.followedAt,
    required this.followingAt,
    required this.pendingAt,
    required this.requestedAt,
  });

  factory TraktAccountActivities.fromJson(Map<String, dynamic> json) {
    return TraktAccountActivities(
      settingsAt: DateTime.parse(json['settings_at']),
      followedAt: DateTime.parse(json['followed_at']),
      followingAt: DateTime.parse(json['following_at']),
      pendingAt: DateTime.parse(json['pending_at']),
      requestedAt: DateTime.parse(json['requested_at']),
    );
  }
}
