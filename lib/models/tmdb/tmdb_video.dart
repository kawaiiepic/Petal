class TmdbVideo {
  final String id;
  final String key; // YouTube video key
  final String name;
  final String site; // "YouTube", "Vimeo", etc.
  final String type; // "Trailer", "Teaser", "Clip", etc.
  final bool official;
  final int size;

  TmdbVideo({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
    required this.size,
  });

  factory TmdbVideo.fromJson(Map<String, dynamic> json) => TmdbVideo(
    id: json['id'] ?? '',
    key: json['key'] ?? '',
    name: json['name'] ?? '',
    site: json['site'] ?? '',
    type: json['type'] ?? '',
    official: json['official'] ?? false,
    size: json['size'] ?? 0,
  );

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';
  String get youtubeThumbnail =>
      'https://img.youtube.com/vi/$key/hqdefault.jpg';
}
