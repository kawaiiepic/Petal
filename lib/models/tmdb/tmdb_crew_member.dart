class TmdbCrewMember {
  final int id;
  final String name;
  final String job;
  final String department;
  final String creditId;
  final String? profilePath;
  final double popularity;

  const TmdbCrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    required this.creditId,
    this.profilePath,
    required this.popularity,
  });

  factory TmdbCrewMember.fromJson(Map<String, dynamic> json) => TmdbCrewMember(
    id: json['id'] as int,
    name: json['name'] as String,
    job: json['job'] as String,
    department: json['department'] as String,
    creditId: json['credit_id'] as String,
    profilePath: json['profile_path'] as String?,
    popularity: (json['popularity'] as num).toDouble(),
  );
}
