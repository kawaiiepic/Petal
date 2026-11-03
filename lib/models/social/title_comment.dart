class TitleComment {
  final String id;
  final String profileId;
  final String name;
  final String? avatar;
  final String body;
  final DateTime createdAt;

  const TitleComment({
    required this.id,
    required this.profileId,
    required this.name,
    required this.body,
    required this.createdAt,
    this.avatar,
  });

  factory TitleComment.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as String?;
    return TitleComment(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatar: avatar != null && !avatar.contains('builtin') ? avatar : null,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['created_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }
}
