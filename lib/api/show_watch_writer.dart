import 'package:dio/dio.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/retryable_write.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/utils/show_watch_plan.dart';

abstract final class ShowWatchWriter {
  static Future<void> save({required String profile, required String profileId,
      required int id, required List<ShowEpisodeTarget> targets,
      required double completion}) async {
    var bulkSupported = true;
    void checkProfile() {
      if (BackendApi.profileCacheKey != profile) throw StateError('Profile changed.');
    }
    Future<void> write(List<ShowEpisodeTarget> episodes) async {
      for (var start = 0; start < episodes.length; start += 100) {
        checkProfile();
        final chunk = episodes.skip(start).take(100).toList();
        if (bulkSupported) {
          try {
            await retryableWrite((options) => BackendApi.dio.post(
              '${Api.ServerUrl}/track/bulk/$profileId/edit',
              options: options, data: {'operations': chunk.map((ep) => {
                'media_type': 'episode', 'tmdb_id': id,
                'edit': {'action': 'set', 'season': ep.season,
                  'episode': ep.episode, 'completion': completion},
              }).toList()}));
            continue;
          } on DioException catch (error) {
            if (error.response?.statusCode != 404 && error.response?.statusCode != 405) rethrow;
            bulkSupported = false;
          }
        }
        // Old backends update an entire show row: serialize requests to avoid
        // contention and stop on failure instead of silently skipping a target.
        for (final ep in chunk) {
          checkProfile();
          await retryableWrite((options) => BackendApi.dio.put(
            '${Api.ServerUrl}/track/state/$profileId/episode/$id',
            options: options, data: {'season': ep.season,
              'episode': ep.episode, 'completion': completion}));
        }
      }
    }
    await ShowWatchPlan.saveVerified(
      targets: targets, completion: completion, write: write,
      read: () async {
        checkProfile();
        final result = await BackendApi.dio.get(
          '${Api.ServerUrl}/track/state/$profileId/episode/$id');
        checkProfile();
        final raw = result.data['result']['episodes'] as List? ?? [];
        return raw.map((e) => EpisodeProgress.fromJson(
          Map<String, dynamic>.from(e as Map))).toList();
      },
    );
  }
}
