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
  String? mediaTitle;
  String? episodeTitle;
  double playbackProgress;

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
    this.mediaTitle,
    this.episodeTitle,
    this.playbackProgress = 0,
  });

  bool get isShow => season != null && episode != null;
  String get displayTitle =>
      mediaTitle?.trim().isNotEmpty == true ? mediaTitle! : title;
  String? get episodeLabel => isShow
      ? 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}${episodeTitle?.isNotEmpty == true ? ' · $episodeTitle' : ''}'
      : null;
  String get displayName =>
      episodeLabel == null ? displayTitle : '$displayTitle — $episodeLabel';

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
    'mediaTitle': mediaTitle,
    'episodeTitle': episodeTitle,
    'playbackProgress': playbackProgress,
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
      mediaTitle: json['mediaTitle'] as String?,
      episodeTitle: json['episodeTitle'] as String?,
      playbackProgress: (json['playbackProgress'] as num?)?.toDouble() ?? 0,
    );
  }
}
