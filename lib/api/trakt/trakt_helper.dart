import 'dart:convert';
import 'dart:io';
import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/authstate.dart';
import 'package:blssmpetal/api/trakt/activity.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_sync.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/models/trakt/profile/extended_profile.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TraktApi {
  // static BrowserClient client = BrowserClient()..withCredentials = true;
  static late final Dio dio;
  static late final PersistCookieJar cookieJar;
  static final String secretKey = "";
  static final AuthState authState = AuthState();

  static Future<List<TraktWatchedShowWithProgress>>? _cachedWatchedShowWithProgress;

  static final ValueNotifier<bool> validSession = ValueNotifier(false);

  static Future<void> init() async {
    prepareCookieManager();
  }

  static Future<void> prepareCookieManager() async {
    dio = Dio();
    final directory = await getApplicationCacheDirectory();
    cookieJar = PersistCookieJar(ignoreExpires: true, storage: FileStorage("${directory.path}/.cookies/"));
    dio.interceptors.add(CookieManager(cookieJar));
  }

  static Future<void> verifySession() async {
    if (kIsWeb) {
      try {
        final response = await dio.get("${Api.ServerUrl}/trakt/verify_session");

        if (response.statusCode == 200) {
          print('Session verified');
          validSession.value = true;
        }
      } catch (err) {
        print('Failed to verify session');
      }
    } else {
      final response = await dio.get("${Api.ServerUrl}/login/verify");

      if (response.data["status"] == "success") {
        authState.setLoggedIn(true);
      }
    }
  }

  static Future<List<Addon>> fetchUserAddons() async {
    print("Fetching user addons");
    final url = '${Api.ServerUrl}/addons/get';
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      print("Addons: ${response.data}");
      final data = response.data;
      final addonsJson = data['addons'] as List;

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

  static Future<ExtendedProfile> userProfile() async {
    final response = await dio.get('${Api.ServerUrl}/trakt/user_profile');

    if (response.statusCode == 200) {
      final profile = ExtendedProfile.fromJson(jsonDecode(response.data));
      TraktCache.set(TraktCache.userProfile, profile.toJson());

      return profile;
    } else {
      throw Exception();
    }
  }

  static Future<TraktLastActivities> lastActivity() async {
    final response = await dio.get('${Api.ServerUrl}/trakt/last_activities');

    if (response.statusCode == 200) {
      return TraktLastActivities.fromJson(jsonDecode(response.data));
    } else {
      throw Exception();
    }
  }

  static Future<void> startWatching(MediaType mediaType, Object object) async {
    var url = '${Api.ServerUrl}/trakt/start_watching';
    await dio.post(url, data: jsonEncode(object));
  }

  static Future<List<TraktShow>> fetchWatched(MediaType mediaType) async {
    final name = mediaType == MediaType.show ? "shows" : "movies";

    final response = await dio.get('${Api.ServerUrl}/trakt/sync_watched/$name');

    if (response.statusCode != 200) return Future.error(Exception('Failed to fetch watched $name'));

    // final list = (res.body as List).map((e) => TraktShow.fromJson(e)).toList();

    print("Fetching watched.");

    final list = (jsonDecode(response.data) as List).map((e) {
      try {
        return TraktShow.fromJson(e as Map<String, dynamic>);
      } catch (err, stack) {
        print('Failed to parse TraktShow: $err');
        print('Stack: $stack');
        print('Data: $e');
        rethrow;
      }
    }).toList();
    return list;
  }

  static Future<Show> fetchShow(String traktId) async {
    final response = await dio.get('${Api.ServerUrl}/trakt/shows/$traktId');

    if (response.statusCode == 200) {
      return Show.fromJson(jsonDecode(response.data));
    }
    return Future.error(Exception());
  }

  static Future<Movie> fetchMovie(String traktId) async {
    final response = await dio.get('${Api.ServerUrl}/trakt/movies/$traktId');

    if (response.statusCode == 200) {
      return Movie.fromJson(jsonDecode(response.data));
    }
    return Future.error(Exception());
  }

  static Future<Search> search(String idType, String id, String type) async {
    final typeFixed = switch (type) {
      "series" => "show",
      String() => type,
    };
    final response = await dio.get('${Api.ServerUrl}/trakt/search/$idType/$id/$typeFixed');

    if (response.statusCode == 200) {
      try {
        final search = Search.fromJson(jsonDecode(response.data)[0]);
        return search;
      } catch (err) {
        print(err);
      }
    }
    return Future.error(Exception());
  }

  static Future<List<TraktSeason>> fetchShowSeasons(String traktId) async {
    final response = await dio.get('${Api.ServerUrl}/trakt/seasons/$traktId');

    if (response.statusCode == 200) {
      final List data = json.decode(response.data);
      return data.map((e) => TraktSeason.fromJson(e)).toList();
    }
    return Future.error(Exception());
  }

  static Future<TraktShowProgress> fetchShowProgress(String traktId) async {
    final response = await dio.get('${Api.ServerUrl}/trakt/show_progress/$traktId');

    if (response.statusCode == 200) {
      final result = TraktShowProgress.fromJson(jsonDecode(response.data));
      return result;
    }

    return Future.error(Exception());
  }

  static Future<List<TraktWatchedShowWithProgress>> fetchWatchedShowWithProgress() async {
    if (_cachedWatchedShowWithProgress != null) return _cachedWatchedShowWithProgress!;

    final watched = (await fetchWatched(MediaType.show));

    print("Fetching Show Progress again.");

    final result = <TraktWatchedShowWithProgress>[];

    for (final w in watched) {
      if (result.length >= 20) break;
      final progress = await fetchShowProgress(w.show.ids.trakt.toString());
      final season = await fetchShowSeasons(w.show.ids.trakt.toString());
      if (progress.nextEpisode != null) {
        result.add(TraktWatchedShowWithProgress(watchedShow: w, show: null, showProgress: progress, seasons: season));
      }
    }

    _cachedWatchedShowWithProgress = Future.value(result);
    return _cachedWatchedShowWithProgress!;
  }

  /// Fetch a single show's watched progress and seasons by Trakt ID
  static Future<TraktWatchedShowWithProgress?> fetchShowWithProgress(int traktId) async {
    // Fetch show metadata
    final watchedShow = await fetchShow(traktId.toString());

    // Fetch progress
    final progress = await fetchShowProgress(traktId.toString());
    if (progress.nextEpisode == null) return null;

    // Fetch seasons
    final seasons = await fetchShowSeasons(traktId.toString());

    return TraktWatchedShowWithProgress(watchedShow: null, show: watchedShow, showProgress: progress, seasons: seasons);
  }
}
