import 'package:blssmpetal/models/stremio/stremio_episode.dart';
import 'package:blssmpetal/models/stremio/stremio_season.dart';
import 'trailer.dart';

class CatalogItem {
  // Core
  final String id;
  final String name;
  final String type;
  final String slug;

  // Media
  final String poster;
  final String background;
  final String logo;

  // Info
  final String description;
  final int year;
  final String runtime;
  final double imdbRating;
  final String awards;
  final String country;
  final String releaseInfo;

  // People
  final List<String> genres;
  final List<String> cast;
  final List<String> directors;
  final List<String> writers;

  // Extras
  final List<Trailer> trailers;

  final List<StremioSeason> seasons;

  CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.slug,
    required this.poster,
    required this.background,
    required this.logo,
    required this.description,
    required this.year,
    required this.runtime,
    required this.imdbRating,
    required this.awards,
    required this.country,
    required this.releaseInfo,
    required this.genres,
    required this.cast,
    required this.directors,
    required this.writers,
    required this.trailers,
    required this.seasons,
  });

  static List<StremioSeason> _buildSeasons(List<dynamic> videos) {
    final Map<int, List<StremioEpisode>> grouped = {};

    for (final v in videos) {
      final ep = StremioEpisode.fromJson(v);
      grouped.putIfAbsent(ep.season, () => []).add(ep);
    }

    return grouped.entries.map((entry) {
      entry.value.sort((a, b) => a.episode.compareTo(b.episode));
      return StremioSeason(number: entry.key, episodes: entry.value);
    }).toList()..sort((a, b) => a.number.compareTo(b.number));
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    int yearInt = 0;
    if (json['year'] != null) {
      String year = json['year'];
      final match = RegExp(r'\d{4}').firstMatch(year);
      yearInt = match != null ? int.parse(match.group(0)!) : 0;
    }

    final videos = json['videos'] as List<dynamic>? ?? [];

    return CatalogItem(
      id: json['id'],
      name: json['name'],
      type: json['type'] ?? '',
      slug: json['slug'] ?? '',

      poster: json['poster'] ?? '',
      background: json['background'] ?? '',
      logo: json['logo'] ?? '',

      description: json['description'] ?? '',
      year: yearInt,
      runtime: json['runtime'] ?? '',
      imdbRating: json['imdbRating'] != null && json['imdbRating'] != "" ? double.parse(json['imdbRating']) : 0,
      awards: json['awards'] ?? '',
      country: (json['country'] is List) ? (json['country'] as List).join(', ') : (json['country'] ?? ''),
      releaseInfo: json['releaseInfo'] ?? '',

      genres: List<String>.from(json['genres'] ?? []),
      cast: List<String>.from(json['cast'] ?? []),
      directors: List<String>.from(json['director'] ?? []),
      writers: List<String>.from(json['writer'] ?? []),

      trailers: (json['trailerStreams'] as List<dynamic>? ?? []).map((t) => Trailer.fromJson(t)).toList(),

      seasons: json['type'] == 'series' ? _buildSeasons(videos) : [],
    );
  }
}
