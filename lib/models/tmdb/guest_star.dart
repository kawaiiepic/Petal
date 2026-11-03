class GuestStar {
  final int id;
  final String name;
  final String character;
  final String creditId;
  final int order;
  final int gender;
  final double popularity;
  final String? profilePath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  GuestStar({
    required this.id,
    required this.name,
    required this.character,
    required this.creditId,
    required this.order,
    required this.gender,
    required this.popularity,
    required this.profilePath,
  });

  String? get profileUrl =>
      profilePath != null ? '$_imageBase$profilePath' : null;

  factory GuestStar.fromJson(Map<String, dynamic> json) {
    return GuestStar(
      id: json['id'],
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      creditId: json['credit_id'] ?? '',
      order: json['order'] ?? 0,
      gender: json['gender'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      profilePath: json['profile_path'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'character': character,
    'credit_id': creditId,
    'order': order,
    'gender': gender,
    'popularity': popularity,
    'profile_path': profilePath,
  };
}
