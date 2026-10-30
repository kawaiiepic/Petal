class CreatedBy {
  final int id;
  final String creditId;
  final String name;
  final int gender;
  final String? profilePath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  CreatedBy({
    required this.id,
    required this.creditId,
    required this.name,
    required this.gender,
    required this.profilePath,
  });

  String? get profileUrl =>
      profilePath != null ? '$_imageBase$profilePath' : null;

  factory CreatedBy.fromJson(Map<String, dynamic> json) => CreatedBy(
    id: json['id'],
    creditId: json['credit_id'] ?? '',
    name: json['name'] ?? '',
    gender: json['gender'] ?? 0,
    profilePath: json['profile_path'],
  );
}
