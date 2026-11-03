import 'package:petal/models/trakt/ids.dart';
import 'package:petal/models/trakt/movie_images.dart';

class Movie {
  final String title;
  final int year;
  final Ids ids;
  final int? runtime; // runtime in minutes
  final double? rating; // rating, e.g., 8.5
  final String? overview; // description/summary
  final List<String>? genres; // list of genres
  final String? certification; // e.g., PG-13, R
  final MovieImages? images; // posters/screenshots

  Movie({
    required this.title,
    required this.year,
    required this.ids,
    this.runtime,
    this.rating,
    this.overview,
    this.genres,
    this.certification,
    this.images,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] ?? '',
      year: json['year'] ?? 0,
      ids: Ids.fromJson(json['ids']),
      runtime: json['runtime'],
      rating: (json['rating'] != null)
          ? (json['rating'] as num).toDouble()
          : null,
      overview: json['overview'],
      genres: (json['genres'] != null)
          ? List<String>.from(json['genres'])
          : null,
      certification: json['certification'],
      images: json['images'] != null
          ? MovieImages.fromJson(json['images'])
          : null,
    );
  }
}
