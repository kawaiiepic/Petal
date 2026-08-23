import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/authstate.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/models/media_state.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class BackendApi {
  static late final Dio dio;
  static late final PersistCookieJar cookieJar;
  static final String secretKey = "";
  static final AuthState authState = AuthState();

  // static final ValueNotifier<bool> validSession = ValueNotifier(false);

  static Future<void> init() async {
    prepareCookieManager();
    BackendApi.authState.addListener(() {
      BackendCache.fetchWatchHistory();
    });
  }

  static Future<void> prepareCookieManager() async {
    dio = Dio();
    final directory = await getApplicationCacheDirectory();
    print(directory.path);
    cookieJar = PersistCookieJar(ignoreExpires: true, storage: FileStorage("${directory.path}/.cookies/"));
    dio.interceptors.add(CookieManager(cookieJar));
  }

  static Future<bool> verifySession() async {
    print("Verifying session");
    try {
      final response = await dio.get("${Api.ServerUrl}/users/verify");
      print("Response code for verify.");
      print(response.data);

      if (response.data["success"] == true) {
        authState.setInitializing(false);
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Expected case: no valid session — just treat as logged out
        print("No valid session");
      } else {
        print("Error verifying session: $e");
      }
    }
    authState.setInitializing(false);
    return false;
  }

  static Future<void> signOut() async {
    await cookieJar.deleteAll();
    authState.setLoggedIn(false);
  }

  static Future<void> uploadProfile(Uint8List imageData) async {
    final mimeType = lookupMimeType('', headerBytes: imageData) ?? 'application/octet-stream';

    await BackendApi.dio.put(
      '${Api.ServerUrl}/profiles/${authState.selectedProfile?.id}/avatar',
      data: imageData,
      options: Options(contentType: mimeType),
    );
  }

  static Future<void> addUserAddon(String manifestUrl, bool forced) async {
    final addon = {"manifest_url": manifestUrl, "forced": forced, "config": "string"};

    await BackendApi.dio.post("${Api.ServerUrl}/addons", data: addon);

    ApiCache.refreshAddons();
  }

  static Future<void> addAddonResource(String addonId, String resource) async {
    await BackendApi.dio.post("${Api.ServerUrl}/addons/$addonId/resources/$resource");
  }

  static Future<void> delAddonResource(String addonId, String resource) async {
    await BackendApi.dio.delete("${Api.ServerUrl}/addons/$addonId/resources/$resource");
  }

  static Future<List<Addon>> fetchUserAddons() async {
    final url = '${Api.ServerUrl}/addons';
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final data = response.data;
      final addonsJson = data['result'] as List;

      // map to list of futures
      final futures = addonsJson.map((json) async {
        var addon = Addon.fromJson(json);
        await addon.fetchManifest();
        return addon;
      }).toList();

      // wait for all futures to complete
      final addons = await Future.wait(futures);
      return addons;
    } else {
      throw Exception('Failed to fetch addons');
    }
  }

  static Future<List<Profile>> profiles() async {
    final url = '${Api.ServerUrl}/profiles';
    final response = await dio.get(url);

    final json = response.data['result'] as List;

    // map to list of futures
    final futures = json.map((json) async {
      var addon = Profile.fromJson(json);
      return addon;
    }).toList();

    // wait for all futures to complete
    final addons = await Future.wait(futures);
    return addons;
  }

  static Future<void> addProfile(String name) async {
    final url = '${Api.ServerUrl}/profiles';
    await dio.post(url, data: {"name": name, "avatar": "builtin:1"});
  }

  static Future<List<ContinueWatchingItem>> continueWatching() async {
    if (authState.selectedProfile == null) return [];
    final url = '${Api.ServerUrl}/track/continue/${authState.selectedProfile?.id}';
    final response = await dio.get(url);

    final items = (response.data['result'] as List<dynamic>).map((e) => ContinueWatchingItem.fromJson(e as Map<String, dynamic>)).toList();

    for (final item in items) {
      if (item is ShowItem) {
        print('Show ${item.tmdbId}, next up: ${item.nextEpisode?.season}x${item.nextEpisode?.episode}');
      } else if (item is MovieItem) {
        print('Movie ${item.tmdbId}, completion: ${item.completion}');
      }
    }
    return items;
  }

  static Future<List<WatchHistoryItem>> watchHistory() async {
    if (authState.selectedProfile == null) return [];
    final url = '${Api.ServerUrl}/track/states/${authState.selectedProfile?.id}';
    final response = await dio.get(url);

    final items = (response.data['result'] as List<dynamic>).map((e) => WatchHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    return items;
  }

  static Future<void> setProgress(int tmdbId, String mediaType, int season, int episode, double progress) async {
    final url = '${Api.ServerUrl}/track/state/${authState.selectedProfile?.id}/$tmdbId/$mediaType/$season/$episode';

    final list = [...BackendCache.continueWatching.value];

    if (progress >= 1.0) {
      // Finished — the server needs to recompute next_episode (via TMDB),
      // so we can't fake this locally. Fire the update, then refetch.
      await dio.put(url, data: {"completion": progress, "updated_at": DateTime.now().millisecondsSinceEpoch});

      await BackendCache.fetchContinueWatching(); // re-fetches and repopulates BackendCache.continueWatching
      return;
    }

    // In-progress — safe to update optimistically without server round-trip.
    if (mediaType == 'movie') {
      final index = list.indexWhere((item) => item is MovieItem && item.tmdbId == tmdbId);

      if (index != -1) {
        list[index] = MovieItem(tmdbId: tmdbId, completion: progress);
      } else {
        list.insert(0, MovieItem(tmdbId: tmdbId, completion: progress));
      }
    } else {
      final showIndex = list.indexWhere((item) => item is ShowItem && item.tmdbId == tmdbId);

      if (showIndex != -1) {
        final show = list[showIndex] as ShowItem;
        final seasons = [...show.seasons];
        final seasonIndex = seasons.indexWhere((s) => s.number == season);

        if (seasonIndex != -1) {
          final episodes = [...seasons[seasonIndex].episodes];
          final episodeIndex = episodes.indexWhere((e) => e.episode == episode);

          if (episodeIndex != -1) {
            episodes[episodeIndex] = SeasonEpisode(episode: episode, completion: progress);
          } else {
            episodes.add(SeasonEpisode(episode: episode, completion: progress));
          }

          seasons[seasonIndex] = Season(number: season, episodes: episodes);
        } else {
          seasons.add(
            Season(
              number: season,
              episodes: [SeasonEpisode(episode: episode, completion: progress)],
            ),
          );
        }

        list[showIndex] = ShowItem(
          tmdbId: tmdbId,
          nextEpisode: NextEpisode(season: season, episode: episode, completion: 0),
          seasons: seasons,
        );
      } else {
        list.insert(
          0,
          ShowItem(
            tmdbId: tmdbId,
            nextEpisode: NextEpisode(season: season, episode: episode, completion: 0),
            seasons: [
              Season(
                number: season,
                episodes: [SeasonEpisode(episode: episode, completion: progress)],
              ),
            ],
          ),
        );
      }
    }

    BackendCache.continueWatching.value = list;

    await dio.put(url, data: {"completion": progress, "updated_at": DateTime.now().millisecondsSinceEpoch});
  }
}
