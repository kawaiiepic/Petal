class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int order;

  CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    required this.order,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    character: json['character'],
    profilePath: json['profile_path'],
    order: json['order'] ?? 0,
  );
}
