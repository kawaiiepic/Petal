class NextEpisode {
  final int season;
  final int episode;
  final double completion;

  NextEpisode({
    required this.season,
    required this.episode,
    required this.completion,
  });

  factory NextEpisode.fromJson(Map<String, dynamic> json) {
    return NextEpisode(
      season: (json['season'] as num).toInt(),
      episode: (json['episode'] as num).toInt(),
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
