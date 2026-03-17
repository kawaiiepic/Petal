import 'package:blssmpetal/api/trakt/trakt_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';

class TraktSync {
  static Future<void> syncUpdates() async {
    final activity = await TraktApi.lastActivity();

    // check each activity timestamp against our last sync
    // final episodesWatched = DateTime.parse(activity.episodes.watchedAt);
    // final showsWatched = DateTime.parse(activities['shows']['watched_at']);

    final settingsCacheAt = await TraktCache.cachedAt(TraktCache.userProfile);

    // activity,shows.watchedAt.isAfter(lastSync);

    if (settingsCacheAt != null && activity.account.settingsAt.isAfter(settingsCacheAt)) {
      await TraktCache.invalidate(TraktCache.userProfile);
    }

    // if (activity.episodes.watchedAt.isAfter(lastSync)) {
    //   // invalidate watched/progress caches
    //   await TraktCache.invalidate('watched_shows');
    //   // await TraktCache.invalidate('watched_movies');

    //   // invalidate individual show progress caches
    //   // final dir = await TraktCache.();
    //   // await for (final file in dir.list()) {
    //   //   if (file.path.contains('show_progress_')) {
    //   //     await file.delete();
    //   //   }
    //   // }
    // }

    // update last sync timestamp
    await TraktCache.set('last_sync', DateTime.now().toIso8601String());
  }
}
