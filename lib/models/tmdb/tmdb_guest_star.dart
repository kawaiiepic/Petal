class TmdbGuestStar {
  final int id;
  final String name;
  final String character;
  final String creditId;
  final int order;
  final String? profilePath;
  final double popularity;

  const TmdbGuestStar({
    required this.id,
    required this.name,
    required this.character,
    required this.creditId,
    required this.order,
    this.profilePath,
    required this.popularity,
  });

  factory TmdbGuestStar.fromJson(Map<String, dynamic> json) => TmdbGuestStar(
    id: json['id'] as int,
    name: json['name'] as String,
    character: json['character'] as String,
    creditId: json['credit_id'] as String,
    order: json['order'] as int,
    profilePath: json['profile_path'] as String?,
    popularity: (json['popularity'] as num).toDouble(),
  );
}
