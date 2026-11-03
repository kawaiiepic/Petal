class Ids {
  final int trakt;
  final String? slug;
  final int? tvdb;
  final String? imdb;
  final int? tmdb;

  Ids({
    required this.trakt,
    required this.slug,
    this.tvdb,
    this.imdb,
    this.tmdb,
  });

  factory Ids.fromJson(Map<String, dynamic> json) {
    return Ids(
      trakt: json['trakt'],
      slug: json['slug'],
      tvdb: json['tvdb'],
      imdb: json['imdb'],
      tmdb: json['tmdb'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trakt': trakt,
      'slug': slug,
      'tvdb': tvdb,
      'imdb': imdb,
      'tmdb': tmdb,
    };
  }
}
