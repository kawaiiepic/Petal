class CrewMember {
  final int id;
  final String name;
  final String job;
  final String department;
  final String creditId;
  final int gender;
  final double popularity;
  final String? profilePath;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  CrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    required this.creditId,
    required this.gender,
    required this.popularity,
    required this.profilePath,
  });

  String? get profileUrl =>
      profilePath != null ? '$_imageBase$profilePath' : null;

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id'],
      name: json['name'] ?? '',
      job: json['job'] ?? '',
      department: json['department'] ?? '',
      creditId: json['credit_id'] ?? '',
      gender: json['gender'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      profilePath: json['profile_path'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'job': job,
    'department': department,
    'credit_id': creditId,
    'gender': gender,
    'popularity': popularity,
    'profile_path': profilePath,
  };
}
