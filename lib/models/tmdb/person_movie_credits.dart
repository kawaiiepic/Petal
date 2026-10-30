import 'package:petal/models/tmdb/person_cast_credit.dart';

class PersonMovieCredits {
  final List<PersonCastCredit> cast;

  PersonMovieCredits({required this.cast});

  factory PersonMovieCredits.fromJson(Map<String, dynamic> json) =>
      PersonMovieCredits(
        cast: (json['cast'] as List<dynamic>? ?? [])
            .map((e) => PersonCastCredit.fromJson(e))
            .toList(),
      );
}
