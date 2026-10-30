class TmdbImage {
  final String filePath;
  final int width;
  final int height;
  final double voteAverage;
  final String? iso6391; // language, null = no language (best for logos)

  static const _base = 'https://image.tmdb.org/t/p/original';

  TmdbImage({
    required this.filePath,
    required this.width,
    required this.height,
    required this.voteAverage,
    required this.iso6391,
  });

  String get url => '$_base$filePath';

  factory TmdbImage.fromJson(Map<String, dynamic> json) => TmdbImage(
    filePath: json['file_path'] ?? '',
    width: json['width'] ?? 0,
    height: json['height'] ?? 0,
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    iso6391: json['iso_639_1'],
  );
}
