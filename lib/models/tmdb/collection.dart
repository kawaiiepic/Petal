class Collection {
  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;

  Collection({
    required this.id,
    required this.name,
    this.posterPath,
    this.backdropPath,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    posterPath: json['poster_path'],
    backdropPath: json['backdrop_path'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
  };
}
