class Profile {
  final String id;
  final String userId;
  final String name;
  final String avatar;
  final String createdAt;

  Profile({required this.id, required this.userId, required this.name, required this.avatar, required this.createdAt});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      avatar: json['avatar'],
      createdAt: json['created_at'],
    );
  }
}
