import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';

class PlaybackItem {
  final int mediaId;
  final Episode? episode;
  final StreamItem? stream;
  final double? progress;
  const PlaybackItem({
    required this.mediaId,
    this.episode,
    this.stream,
    this.progress,
  });
  bool get isOffline => stream?.isLocal ?? false;
}
