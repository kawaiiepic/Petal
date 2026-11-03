import 'package:petal/models/tmdb/tmdb_image_urls.dart';

class TmdbMedia {
  final int id;
  final String mediaType;
  final String title;
  final String posterPath;
  final String backdropPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;

  TmdbMedia({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
  });

  String? get posterUrl => '${TmdbImageUrls.poster}$posterPath';

  factory TmdbMedia.fromJson(Map<String, dynamic> json) {
    return TmdbMedia(
      id: json['id'],
      mediaType: json['media_type'] ?? '',
      title: json['title'] ?? json['name'] ?? '', // movie vs tv
      posterPath: "https://image.tmdb.org/t/p/original${json['poster_path']}",
      backdropPath:
          "https://image.tmdb.org/t/p/original${json['backdrop_path']}",
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'],
    );
  }
}
