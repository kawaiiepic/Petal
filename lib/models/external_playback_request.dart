import 'package:petal/models/episode.dart';
import 'package:petal/models/media_type.dart';

class ExternalPlaybackRequest {
  final int mediaId;
  final Episode? episode;
  final String label;
  final String? profileKey;
  const ExternalPlaybackRequest({
    required this.mediaId,
    required this.label,
    this.episode,
    this.profileKey,
  });
  MediaType get type => episode == null ? MediaType.movie : MediaType.show;
}
