/// A single movie in an actor's filmography (from /person/{id} movie_credits).
class PersonCastCredit {
  final int id;
  final String title;
  final String? posterPath;
  final String? character;
  final double voteAverage;
  final String releaseDate;

  PersonCastCredit({
    required this.id,
    required this.title,
    this.posterPath,
    this.character,
    required this.voteAverage,
    required this.releaseDate,
  });

  factory PersonCastCredit.fromJson(Map<String, dynamic> json) =>
      PersonCastCredit(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        posterPath: json['poster_path'],
        character: json['character'],
        voteAverage: (json['vote_average'] ?? 0).toDouble(),
        releaseDate: json['release_date'] ?? '',
      );

  /// Sort key so the newest movies show first.
  int get releaseYear {
    final year = releaseDate.split('-').firstOrNull;
    return int.tryParse(year ?? '') ?? 0;
  }
}
