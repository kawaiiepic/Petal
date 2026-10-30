import 'package:petal/models/tmdb/tmdb_image.dart';

class TmdbImages {
  final List<TmdbImage> backdrops;
  final List<TmdbImage> posters;
  final List<TmdbImage> logos;

  TmdbImages({
    required this.backdrops,
    required this.posters,
    required this.logos,
  });

  TmdbImage? get preferredLogo {
    final candidates = logos
        .where((image) => image.filePath.isNotEmpty)
        .toList();
    int languageRank(TmdbImage image) => switch (image.iso6391) {
      'en' => 0,
      null || '' => 1,
      _ => 2,
    };
    candidates.sort((a, b) {
      final language = languageRank(a).compareTo(languageRank(b));
      if (language != 0) return language;
      final rating = b.voteAverage.compareTo(a.voteAverage);
      return rating != 0 ? rating : b.width.compareTo(a.width);
    });
    return candidates.firstOrNull;
  }

  factory TmdbImages.fromJson(Map<String, dynamic> json) => TmdbImages(
    backdrops: (json['backdrops'] as List? ?? [])
        .map((e) => TmdbImage.fromJson(e))
        .toList(),
    posters: (json['posters'] as List? ?? [])
        .map((e) => TmdbImage.fromJson(e))
        .toList(),
    logos: (json['logos'] as List? ?? [])
        .map((e) => TmdbImage.fromJson(e))
        .toList(),
  );
}
