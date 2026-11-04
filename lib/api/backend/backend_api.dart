import 'package:flutter/foundation.dart';
import 'package:petal/api/retryable_write.dart';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/auth_state.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/backend/watch_presence_client.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/next_episode.dart';
import 'package:petal/models/watch_history/season.dart';
import 'package:petal/models/watch_history/season_episode.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BackendApi {
  static late final Dio dio;
  static late final PersistCookieJar cookieJar;
  static final String secretKey = "";
  static final AuthState authState = AuthState();

  static String? get profileCacheKey =>
      authState.loggedIn && authState.selectedProfile != null
      ? '${authState.id}:${authState.selectedProfile!.id}'
      : null;

  static WatchPresenceClient presence = WatchPresenceClient();

  static Future<void> init() async {
    await prepareCookieManager();
    BackendApi.authState.addListener(BackendCache.onAuthChanged);

    presence.connect();

    presence.sessions.listen((s) {
      BackendCache.sessions.value = s;
      print(s.toString());
    });
  }

  static Future<void> prepareCookieManager() async {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    final directory = await getApplicationCacheDirectory();
    print(directory.path);
    cookieJar = PersistCookieJar(
      storage: FileStorage("${directory.path}/.cookies/"),
    );
    dio.interceptors.add(CookieManager(cookieJar));
    // Runs after CookieManager: inspect presence, never cookie/token contents.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authPath(options.uri.path)) {
          final cookie = options.headers.entries
              .where((entry) => entry.key.toLowerCase() == 'cookie')
              .map((entry) => entry.value.toString()).join(';');
          authDebug('request ${options.method} ${options.uri.path} '
              'scheme=${options.uri.scheme} host=${options.uri.host} '
              'authCookieSent=${RegExp(r"(^|;\s*)auth=").hasMatch(cookie)}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (_authPath(response.requestOptions.uri.path)) {
          final cookies = response.headers['set-cookie'] ?? const <String>[];
          authDebug('response ${response.requestOptions.uri.path} '
              'status=${response.statusCode} '
              'success=${response.data is Map ? response.data['success'] == true : false} '
              'setCookieCount=${cookies.length} '
              'setsAuthCookie=${cookies.any((value) => value.startsWith('auth='))}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (_authPath(error.requestOptions.uri.path)) {
          authDebug('request failed ${error.requestOptions.uri.path} '
              'status=${error.response?.statusCode} type=${error.type.name} '
              'reason=${_authReason(error.response?.data)}');
        }
        handler.next(error);
      },
    ));

  }

  static bool _authPath(String path) =>
      path == '/users/login' || path == '/users/register' ||
      path == '/users/verify' || path == '/profiles' || path == '/profiles/';

  static void authDebug(String message) {
    if (kDebugMode) debugPrint('[Petal auth] $message');
  }

  static String _authReason(dynamic data) {
    final error = data is Map ? data['error'] : null;
    // Only known public errors; arbitrary response bodies may contain secrets.
    const known = {
      'Unauthorized', 'Invalid token', 'Session expired or revoked',
      'Authentication is not configured', 'User no longer exists',
      'Backend maintenance',
    };
    return known.contains(error) ? error as String : 'unclassified';
  }

  static Future<void> debugAuthCookies(String stage) async {
    if (!kDebugMode) return;
    try {
      final uri = Uri.parse('${Api.ServerUrl}/users/verify');
      final cookies = await cookieJar.loadForRequest(uri);
      final auth = cookies.where((cookie) => cookie.name == 'auth').toList();
      authDebug('$stage cookieJar: matchingAuthCookies=${auth.length} '
          'secure=${auth.any((cookie) => cookie.secure)} '
          'expired=${auth.any((cookie) =>
            cookie.expires?.isBefore(DateTime.now()) ?? false)}');
    } catch (error) {
      authDebug('$stage cookieJar read failed: ${error.runtimeType}');
    }
  }

  static Future<bool> verifySession() async {
    authDebug("Starting verification");
    var stage = "verify";

    try {
      await debugAuthCookies("before verification");
      final response = await dio.get("${Api.ServerUrl}/users/verify");

      if (response.data["success"] == true) {
        final user = Map<String, dynamic>.from(response.data["user"]);

        authState.setLoggedIn(user);
        authState.setInitializing(false);

        stage = 'profiles';
        authDebug('Token verified; loading profiles');
        final profiles = await BackendApi.profiles();
        authDebug('Profile load succeeded: count=${profiles.length}');
        if (profiles.isNotEmpty) {
          authState.setProfile(profiles.first);
        }

        return true;
      }
    } on DioException catch (e) {
      authDebug('$stage failed: status=${e.response?.statusCode} '
          'type=${e.type.name} reason=${_authReason(e.response?.data)}');
    } catch (e) {
      authDebug('$stage failed: ${e.runtimeType}');
    }

    // Clear logged-in state here using your authState API.
    authState.setInitializing(false);
    return false;
  }

  static Future<void> signOut() async {
    try {
      await dio.post('${Api.ServerUrl}/users/sessions/logout');
    } catch (_) {
      // Local sign-out must still work offline or against an older backend.
    } finally {
      await cookieJar.deleteAll();
      authState.setLoggedIn(null);
    }
  }

  static Future<void> uploadProfile(Uint8List imageData) async {
    final mimeType =
        lookupMimeType('', headerBytes: imageData) ??
        'application/octet-stream';

    print(mimeType);

    await BackendApi.dio.put(
      '${Api.ServerUrl}/profiles/${authState.selectedProfile?.id}/avatar',
      data: imageData,
      options: Options(contentType: mimeType),
    );
  }

  static Future<void> addUserAddon(String manifestUrl, bool forced) async {
    final addon = {
      "manifest_url": manifestUrl,
      "forced": forced,
      "config": "string",
    };

    await BackendApi.dio.post("${Api.ServerUrl}/addons", data: addon);

    ApiCache.refreshAddons();
  }

  static Future<void> deleteUserAddon(String addonId) async {
    await BackendApi.dio.delete("${Api.ServerUrl}/addons/$addonId");

    ApiCache.refreshAddons();
  }

  static Future<void> addAddonResource(String addonId, String resource) async {
    await BackendApi.dio.post(
      "${Api.ServerUrl}/addons/$addonId/resources/$resource",
    );
  }

  static Future<void> delAddonResource(String addonId, String resource) async {
    await BackendApi.dio.delete(
      "${Api.ServerUrl}/addons/$addonId/resources/$resource",
    );
  }

  static Future<List<Addon>> fetchUserAddons() async {
    final url = '${Api.ServerUrl}/addons';
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final data = response.data;
      final addonsJson = data['result'] as List;

      final futures = addonsJson.map((json) async {
        var addon = Addon.fromJson(json);
        await addon.fetchManifest();
        return addon;
      }).toList();

      final addons = await Future.wait(futures);
      return addons;
    } else {
      throw Exception('Failed to fetch addons');
    }
  }

  static Future<void> fetchSelectedProfile() async {
    BackendApi.authState.setProfile((await BackendApi.profiles()).first);
  }

  static Future<List<Profile>> profiles() async {
    final url = '${Api.ServerUrl}/profiles';
    final response = await dio.get(url);

    final json = response.data['result'] as List;

    final futures = json.map((json) async {
      var addon = Profile.fromJson(json);
      return addon;
    }).toList();

    final addons = await Future.wait(futures);
    return addons;
  }

  static Future<void> addProfile(String name) async {
    final url = '${Api.ServerUrl}/profiles';
    await dio.post(url, data: {"name": name, "avatar": "builtin:1"});
  }

  static Future<List<ContinueWatchingItem>> continueWatching() async {
    if (authState.selectedProfile == null) return [];
    final url =
        '${Api.ServerUrl}/track/continue/${authState.selectedProfile?.id}';
    final response = await dio.get(url);

    final items = (response.data['result'] as List<dynamic>)
        .map((e) => ContinueWatchingItem.fromJson(e as Map<String, dynamic>))
        .toList();

    for (final item in items) {
      if (item is ShowItem) {
        print(
          'Show ${item.tmdbId}, next up: ${item.nextEpisode?.season}x${item.nextEpisode?.episode}',
        );
      } else if (item is MovieItem) {
        print('Movie ${item.tmdbId}, completion: ${item.completion}');
      }
    }
    return items;
  }

  static Future<List<WatchHistoryItem>> watchHistory() async {
    final profile = profileCacheKey;
    final id = authState.selectedProfile?.id;
    if (profile == null || id == null) return [];
    final items = <WatchHistoryItem>[];
    final cursors = <String>{};
    String? cursor;
    do {
      if (profileCacheKey != profile) return [];
      final response = await dio.get('${Api.ServerUrl}/track/states/$id',
        queryParameters: {'limit': 200, if (cursor != null) 'cursor': cursor});
      if (profileCacheKey != profile) return [];
      items.addAll((response.data['result'] as List)
          .map((e) => WatchHistoryItem.fromJson(Map<String, dynamic>.from(e as Map))));
      cursor = response.data['next_cursor'] as String?;
      if (cursor != null && !cursors.add(cursor)) {
        throw const FormatException('Backend repeated its history cursor');
      }
    } while (cursor != null);
    return items;
  }

  static Future<void> setProgress(
    int tmdbId,
    MediaType mediaType,
    double progress, {
    int? season,
    int? episode,
    DateTime? watchedAt,
    bool notify = false,
    bool refresh = true,
  }) async {
    final profileId = authState.selectedProfile?.id;
    final profileKey = profileCacheKey;
    if (profileId == null || profileKey == null) return;
    BackendCache.invalidateProgress(profileKey: profileKey);
    final type = mediaType.toBackendSafe;
    final url = '${Api.ServerUrl}/track/state/$profileId/$type/$tmdbId';

    final data = <String, dynamic>{'completion': progress};

    if (season != null) data['season'] = season;
    if (episode != null) data['episode'] = episode;
    if (watchedAt != null) {
      data['watched_at'] = watchedAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    }

    final list = [...BackendCache.continueWatching.value];

    if (progress >= 1.0) {
      await _writeProgress(url, data, profileKey);
      if (notify) {
        AppNotifications.sendNotification(
          const Text('Updated'),
          const Text('Episode has been marked as watched.'),
        );
      }
      if (refresh && profileCacheKey == profileKey) {
        await Future.wait([
          BackendCache.fetchContinueWatching(),
          BackendCache.fetchWatchHistory(),
        ]);
      }
      return;
    }

    final lastWatched = watchedAt ?? DateTime.now();
    if (type == 'movie') {
      final index = list.indexWhere(
        (item) => item is MovieItem && item.tmdbId == tmdbId,
      );
      if (index != -1) {
        list[index] = MovieItem(
          tmdbId: tmdbId,
          completion: progress,
          lastWatched: lastWatched,
        );
      } else {
        list.insert(
          0,
          MovieItem(
            tmdbId: tmdbId,
            completion: progress,
            lastWatched: lastWatched,
          ),
        );
      }
    } else if (season != null && episode != null) {
      final showIndex = list.indexWhere(
        (item) => item is ShowItem && item.tmdbId == tmdbId,
      );

      if (showIndex != -1) {
        final show = list[showIndex] as ShowItem;
        final seasons = [...show.seasons];
        final seasonIndex = seasons.indexWhere((s) => s.number == season);

        if (seasonIndex != -1) {
          final episodes = [...seasons[seasonIndex].episodes];
          final episodeIndex = episodes.indexWhere((e) => e.episode == episode);
          if (episodeIndex != -1) {
            episodes[episodeIndex] = SeasonEpisode(
              episode: episode,
              completion: progress,
            );
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
          lastWatched: lastWatched,
          nextEpisode: NextEpisode(
            season: season,
            episode: episode,
            completion: progress,
          ),
          seasons: seasons,
        );
      } else {
        list.insert(
          0,
          ShowItem(
            tmdbId: tmdbId,
            lastWatched: lastWatched,
            nextEpisode: NextEpisode(
              season: season,
              episode: episode,
              completion: progress,
            ),
            seasons: [
              Season(
                number: season,
                episodes: [
                  SeasonEpisode(episode: episode, completion: progress),
                ],
              ),
            ],
          ),
        );
      }
    }

    if (profileCacheKey == profileKey)
      BackendCache.continueWatching.value = list;
    await _writeProgress(url, data, profileKey);
  }

  static Future<void> _writeProgress(
    String url,
    Map<String, dynamic> data,
    String profileKey,
  ) async {
    await retryableWrite((options) => dio.put(url, data: data, options: options));
    BackendCache.invalidateProgress(profileKey: profileKey);
  }
}
