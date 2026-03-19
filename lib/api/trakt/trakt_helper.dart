import 'dart:convert';
import 'dart:io';
import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/activity.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_sync.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/models/trakt/profile/extended_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TraktApi {
  static BrowserClient client = BrowserClient()..withCredentials = true;

  static Future<List<TraktWatchedShowWithProgress>>? _cachedWatchedShowWithProgress;

  static final ValueNotifier<bool> validSession = ValueNotifier(false);

  static Future<void> verifySession() async {
    try {
      final response = await client.get(Uri.parse("${Api.ServerUrl}/trakt/verify_session"));

      if (response.statusCode == 200) {
        print('Session verified');
        validSession.value = true;
      }
    } catch (err) {
      print('Failed to verify session');
    }
  }

  static Future<List<Addon>> fetchUserAddons() async {
    print("Fetching user addons");
    final url = '${Api.ServerUrl}/addons/get'; // your server URL
    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final addonsJson = data['addons'] as List;

      // map to list of futures
      final futures = addonsJson.map((json) async {
        var addon = Addon.fromJson(json);
        await addon.fetchManifest(); // now allowed
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
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/user_profile'));

    if (response.statusCode == 200) {
      final profile = ExtendedProfile.fromJson(jsonDecode(response.body));
      TraktCache.set(TraktCache.userProfile, profile.toJson());

      return profile;
    } else {
      throw Exception();
    }
  }

  static Future<TraktLastActivities> lastActivity() async {
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/last_activities'));

    if (response.statusCode == 200) {
      return TraktLastActivities.fromJson(jsonDecode(response.body));
    } else {
      throw Exception();
    }
  }

  static Future<void> startWatching(MediaType mediaType, Object object) async {
    var url = Uri.parse('${Api.ServerUrl}/trakt/start_watching');
    await client.post(url, body: jsonEncode(object));
  }

  static Future<List<TraktShow>> fetchWatched(MediaType mediaType) async {
    final name = mediaType == MediaType.show ? "shows" : "movies";

    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/sync_watched/$name'));

    if (response.statusCode != 200) return Future.error(Exception('Failed to fetch watched $name'));

    // final list = (res.body as List).map((e) => TraktShow.fromJson(e)).toList();

    print("Fetching watched.");

    final list = (jsonDecode(response.body) as List).map((e) {
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
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/shows/$traktId'));

    if (response.statusCode == 200) {
      return Show.fromJson(jsonDecode(response.body));
    }
    return Future.error(Exception());
  }

    static Future<Movie> fetchMovie(String traktId) async {
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/movies/$traktId'));

    if (response.statusCode == 200) {
      return Movie.fromJson(jsonDecode(response.body));
    }
    return Future.error(Exception());
  }

  static Future<Search> search(String id_type, String id, String type) async {
    final typeFixed = switch (type) {
      "series" => "show",
      String() => type,
    };
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/search/$id_type/$id/$typeFixed'));

    print('${Api.ServerUrl}/trakt/search/$id_type/$id/$typeFixed');
    print(response.body);

    if (response.statusCode == 200) {
      try {
        final search = Search.fromJson(jsonDecode(response.body)[0]);
        return search;
      } catch (err) {
        print(err);
      }
    }
    return Future.error(Exception());
  }

  static Future<List<TraktSeason>> fetchShowSeasons(String traktId) async {
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/seasons/$traktId'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => TraktSeason.fromJson(e)).toList();
    }
    return Future.error(Exception());
  }

  static Future<TraktShowProgress> fetchShowProgress(String traktId) async {
    final response = await client.get(Uri.parse('${Api.ServerUrl}/trakt/show_progress/$traktId'));

    if (response.statusCode == 200) {
      final result = TraktShowProgress.fromJson(jsonDecode(response.body));
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
