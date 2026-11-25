class ActivityItem {
  final String profileId;
  final String name;
  final String? avatar;
  final int tmdbId;
  final String mediaType;
  final DateTime at;
  final int? season;
  final int? episode;

  bool get isEpisode => mediaType != 'movie' && season != null && episode != null && episode! > 0;

  const ActivityItem({
    required this.profileId,
    required this.name,
    required this.tmdbId,
    required this.mediaType,
    required this.at,
    this.avatar,
    this.season,
    this.episode,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as String?;
    return ActivityItem(
      profileId: json['profile_id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatar: avatar != null && !avatar.contains('builtin') ? avatar : null,
      tmdbId: (json['tmdb_id'] as num).toInt(),
      mediaType: json['media_type'] as String? ?? 'show',
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      at: DateTime.fromMillisecondsSinceEpoch(
        ((json['updated_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }
}
