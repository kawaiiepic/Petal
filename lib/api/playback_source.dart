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
    return StreamApi.autoSelectStream(
      await options(mediaId: mediaId, episode: episode, includeExternal: true),
    );
  }

  static Future<List<StreamItem>> options({
    required int mediaId,
    Episode? episode,
    bool includeExternal = false,
  }) async {
    final imdb = episode != null
        ? (await TMDB.tvShow(mediaId)).imdbId
        : (await TMDB.movie(mediaId)).imdbId;
    if (imdb == null || imdb.isEmpty) return [];
    final streams = await StreamApi.fetchStreams(imdb, episode);
    final seen = <String>{};
    return streams
        .where(
          (source) =>
              (includeExternal || !source.external) &&
              source.url.isNotEmpty &&
              seen.add(source.url),
        )
        .toList();
  }
}
