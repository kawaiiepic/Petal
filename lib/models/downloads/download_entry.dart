import 'package:petal/models/downloads/download_status.dart';

class DownloadEntry {
  final String id;
  final String title;
  final int tmdbId;
  final int? season;
  final int? episode;
  String? url;
  String? path;
  double progress;
  DownloadStatus status;
  String? error;

  DownloadEntry({
    required this.id,
    required this.title,
    required this.tmdbId,
    this.season,
    this.episode,
    this.url,
    this.path,
    this.progress = 0,
    this.status = DownloadStatus.queued,
    this.error,
  });

  bool get isShow => season != null && episode != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'tmdbId': tmdbId,
    'season': season,
    'episode': episode,
    'url': url,
    'path': path,
    'progress': progress,
    'status': status.name,
    'error': error,
  };

  factory DownloadEntry.fromJson(Map<String, dynamic> json) {
    return DownloadEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Download',
      tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      url: json['url'] as String?,
      path: json['path'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status: DownloadStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      error: json['error'] as String?,
    );
  }
}
