class SocialProfile {
  final String id;
  final String name;
  final String? avatar;
  final bool following;

  const SocialProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.following = false,
  });

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as String?;
    return SocialProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatar: avatar != null && !avatar.contains('builtin') ? avatar : null,
      following: json['following'] == true,
    );
  }
}
