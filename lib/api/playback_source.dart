import 'package:petal/api/stream_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';

abstract final class PlaybackSource {
  /// Explicit sources, including downloaded files, never perform discovery.
  static Future<StreamItem?> resolve({
    required int mediaId,
    Episode? episode,
    StreamItem? selected,
  }) async {
    if (selected != null) return selected;
    final imdb = episode != null
        ? (await TMDB.tvShow(mediaId)).imdbId
        : (await TMDB.movie(mediaId)).imdbId;
    if (imdb == null || imdb.isEmpty) return null;
    return StreamApi.autoSelectStream(
      await StreamApi.fetchStreams(imdb, episode),
    );
  }
}
