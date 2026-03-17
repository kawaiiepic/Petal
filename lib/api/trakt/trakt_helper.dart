import 'dart:convert';
import 'dart:io';
import 'package:blssmpetal/api/trakt/activity.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_sync.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/models/trakt/profile/extended_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TraktApi {
  static const String baseUrl = 'https://api.trakt.tv';
  static const clientId = '0a4b47986a50894f19f24aad11101514993592db3c9a63e12e2d573504e1adbb';
  static const clientSecret = '4640a2e220cc5e8a0eebf692389d28cd542b92e893850d0e737456835c85a4b5';

  static final ValueNotifier<String?> accessToken = ValueNotifier(null);

  static List<TraktWatchedShowWithProgress>? _cachedWatchedShowWithProgress;

  static Future<bool> loadAccessCode() async {
    if (kIsWeb) {
      print("Running on Web!");
      return false;
    } else {
      final directory = await getApplicationCacheDirectory();
      var file = File('${directory.path}/trakt.json');

      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());

        if (json["access_token"] != null) {
          accessToken.value = json["access_token"];
        }

        await TraktSync.syncUpdates();

        return true;
      } else {
        print("Missing Trakt API Code");
        return false;
      }
    }
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${accessToken.value}',
    'trakt-api-version': '2',
    'trakt-api-key': clientId,
  };

  static Future<ExtendedProfile> userProfile() async {
    final cacheProfile = await TraktCache.get(TraktCache.userProfile);

    if (cacheProfile != null) return ExtendedProfile.fromJson(cacheProfile);

    var url = Uri.https('api.trakt.tv', '/users/me', {'extended': 'full'});
    var response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final profile = ExtendedProfile.fromJson(jsonDecode(response.body));
      TraktCache.set(TraktCache.userProfile, profile.toJson());

      return profile;
    } else {
      throw Exception();
    }
  }

  static Future<TraktLastActivities> lastActivity() async {
    var url = Uri.https('api.trakt.tv', '/sync/last_activities');
    var response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return TraktLastActivities.fromJson(jsonDecode(response.body));
    } else {
      throw Exception();
    }
  }

  static Future<void> startWatching(MediaType mediaType, Object object) async {
    var url = Uri.https('api.trakt.tv', '/scrobble/start');
    await http.post(url, headers: _headers, body: jsonEncode(object));
  }

  static Future<List<TraktShow>> fetchWatched(MediaType mediaType) async {
    final name = mediaType == MediaType.show ? "shows" : "movies";
    final cacheKey = "${TraktCache.syncWatched}/$name";

    final cached = await TraktCache.get(cacheKey);
    if (cached != null) {
      return (jsonDecode(cached) as List).map((e) => TraktShow.fromJson(e)).toList();
    }

    final url = Uri.parse('$baseUrl/sync/watched/$name?extended=full');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) return Future.error(Exception('Failed to fetch watched $name'));

    // final list = (res.body as List).map((e) => TraktShow.fromJson(e)).toList();

    print("Fetching watched.");

    final list = (jsonDecode(res.body) as List).map((e) {
      try {
        return TraktShow.fromJson(e as Map<String, dynamic>);
      } catch (err, stack) {
        print('Failed to parse TraktShow: $err');
        print('Stack: $stack');
        print('Data: $e');
        rethrow;
      }
    }).toList();
    await TraktCache.set(cacheKey, jsonEncode(list));
    return list;
  }

  static Future<TraktShow> fetchShow(String id) async {
    final url = Uri.parse('$baseUrl/shows/$id?extended=full');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      return TraktShow.fromJson(jsonDecode(res.body));
    }
    return Future.error(Exception());
  }

  static Future<List<TraktSeason>> fetchShowSeasons(String traktId) async {
    final url = Uri.parse('$baseUrl/shows/$traktId/seasons?extended=episodes,full');
    final res = await http.get(url, headers: _headers);

    print("Fetching seasons");

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => TraktSeason.fromJson(e)).toList();
    }
    return Future.error(Exception());
  }

  static Future<TraktShowProgress> fetchShowProgress(int traktId) async {
    final key = TraktCache.showProgress.replaceAll("%s", traktId.toString());
    final cacheProgress = await TraktCache.get(key);

    if (cacheProgress != null) {
      try {
        return TraktShowProgress.fromJson(cacheProgress);
      } catch (e) {
        print('cache parse error: $e');
        // fall through to API call
      }
    }

    final url = Uri.parse('$baseUrl/shows/$traktId/progress/watched?last_activity=watched');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      final result = TraktShowProgress.fromJson(jsonDecode(res.body));
      TraktCache.set(key, result);
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
      if (result.length >= 10) break;
      final progress = await fetchShowProgress(w.show.ids.trakt);
      final season = await fetchShowSeasons(w.show.ids.trakt.toString());
      print(progress);
      if (progress.nextEpisode != null) {
        result.add(TraktWatchedShowWithProgress(watchedShow: w, showProgress: progress, seasons: season));
      }
    }

    _cachedWatchedShowWithProgress = result;
    return _cachedWatchedShowWithProgress!;
  }
}
