import 'dart:convert';
import 'dart:io';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/models/trakt/profile/extended_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TraktApi {
  static const String baseUrl = 'https://api.trakt.tv';
  static const clientId = '0a4b47986a50894f19f24aad11101514993592db3c9a63e12e2d573504e1adbb';
  static const clientSecret = '4640a2e220cc5e8a0eebf692389d28cd542b92e893850d0e737456835c85a4b5';

  static String accessToken = '';

  static Future<String> getAccessToken() async {
    return accessToken;
  }

  static Future<bool> loadAccessCode() async {
    if (kIsWeb) {
      print("Running on Web!");
      return false;
    } else {
      final directory = await getApplicationCacheDirectory();
      var file = File('${directory.path}/trakt.json');

      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        print(json);

        if (json["access_token"] != null) {
          accessToken = json["access_token"];
        }
        return true;
      } else {
        return false;
      }
    }
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
    'trakt-api-version': '2',
    'trakt-api-key': clientId,
  };

  static Future<ExtendedProfile> userProfile() async {
    final token = await getAccessToken();
    var url = Uri.https('api.trakt.tv', '/users/me', {'extended': 'full'});
    var response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final profile = profileFromJson(response.body);

      return profile;
    } else {
      throw Exception();
    }
  }

  static Future<void> startWatching(MediaType mediaType, Object object) async {
    var url = Uri.https('api.trakt.tv', '/scrobble/start');
    await http.post(url, headers: _headers, body: jsonEncode(object));
  }

  static Future<void> watched(MediaType mediaType) async {
    var url = Uri.https('api.trakt.tv', '/sync/watched/shows', {'extended': 'full'});
    var response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      var watched = print(response.body);
    }
  }

  static Future<List<TraktNextUpItem>> getNextUp(MediaType mediaType) async {
    var name = mediaType == MediaType.show ? "shows" : "movies";
    final url = Uri.parse('$baseUrl/sync/watched/$name');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => TraktNextUpItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch next up');
    }
  }

  static Future<TraktShowProgress> fetchShowProgress(int traktId) async {
    final url = Uri.parse('$baseUrl/shows/$traktId/progress/watched');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch progress');
    }

    return TraktShowProgress.fromJson(jsonDecode(res.body));
  }

  static Future<List<TraktHistoryItem>> getWatchHistory({int limit = 50}) async {
    final url = Uri.parse('$baseUrl/sync/history?limit=$limit');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => TraktHistoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch watch history');
    }
  }

  static Future<List<dynamic>> getWatchedShows({int limit = 50, int page = 1}) async {
    final url = Uri.parse('$baseUrl/sync/watched/shows?limit=$limit&page=$page');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch watched shows: ${res.statusCode} ${res.body}');
    }
  }

  static Future<List<dynamic>> getWatchedMovies({int limit = 50, int page = 1}) async {
    final url = Uri.parse('$baseUrl/sync/watched/movies?limit=$limit&page=$page');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch watched movies: ${res.statusCode} ${res.body}');
    }
  }
}
