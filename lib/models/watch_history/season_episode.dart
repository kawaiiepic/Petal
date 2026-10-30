class SeasonEpisode {
  final int episode;
  final double completion;

  SeasonEpisode({required this.episode, required this.completion});

  factory SeasonEpisode.fromJson(Map<String, dynamic> json) {
    return SeasonEpisode(
      episode: (json['episode'] as num).toInt(),
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
