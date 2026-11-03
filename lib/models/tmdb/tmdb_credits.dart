import 'package:petal/models/tmdb/cast_member.dart';
import 'package:petal/models/tmdb/crew_member.dart';

class TmdbCredits {
  final List<CastMember> cast;
  final List<CrewMember> crew;

  TmdbCredits({required this.cast, required this.crew});

  factory TmdbCredits.fromJson(Map<String, dynamic> json) => TmdbCredits(
    cast: (json['cast'] as List<dynamic>? ?? [])
        .map((e) => CastMember.fromJson(e))
        .toList(),
    crew: (json['crew'] as List<dynamic>? ?? [])
        .map((e) => CrewMember.fromJson(e))
        .toList(),
  );

  /// Convenience getter — first director found in crew.
  String? get director {
    for (final c in crew) {
      if (c.job == 'Director') return c.name;
    }
    return null;
  }
}
