class UpcomingItem {
  final int tmdbId;
  final String showName;
  final String episodeName;
  final int season;
  final int episode;
  final DateTime airDate;
  final String? image;

  const UpcomingItem({
    required this.tmdbId,
    required this.showName,
    required this.episodeName,
    required this.season,
    required this.episode,
    required this.airDate,
    this.image,
  });
}
