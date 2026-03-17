class StremioEpisode {
  final int season;
  final int episode;
  final String title;
  final String overview;
  final String thumbnail;

  StremioEpisode({required this.season, required this.episode, required this.title, required this.overview, required this.thumbnail});

  factory StremioEpisode.fromJson(Map<String, dynamic> json) {
    return StremioEpisode(
      season: json['season'],
      episode: json['episode'],
      title: json['name'] ?? '',
      overview: json['overview'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}
