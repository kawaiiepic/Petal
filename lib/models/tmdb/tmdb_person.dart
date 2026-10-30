import 'package:petal/models/tmdb/person_movie_credits.dart';

class TmdbPerson {
  final int id;
  final String name;
  final String? biography;
  final String? profilePath;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final List<String> alsoKnownAs;
  final String? knownForDepartment;
  final PersonMovieCredits? movieCredits;

  TmdbPerson({
    required this.id,
    required this.name,
    this.biography,
    this.profilePath,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    required this.alsoKnownAs,
    this.knownForDepartment,
    this.movieCredits,
  });

  factory TmdbPerson.fromJson(Map<String, dynamic> json) => TmdbPerson(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    biography: json['biography'],
    profilePath: json['profile_path'],
    birthday: json['birthday'],
    deathday: json['deathday'],
    placeOfBirth: json['place_of_birth'],
    alsoKnownAs: (json['also_known_as'] as List<dynamic>? ?? []).cast<String>(),
    knownForDepartment: json['known_for_department'],
    movieCredits: json['movie_credits'] != null
        ? PersonMovieCredits.fromJson(json['movie_credits'])
        : null,
  );
}
