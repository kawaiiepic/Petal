import 'dart:convert';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:http/http.dart' as http;

class TraktApi {
  static const String baseUrl = 'https://api.trakt.tv';
  final String clientId;
  final String accessToken;

  TraktApi({required this.clientId, required this.accessToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
    'trakt-api-version': '2',
    'trakt-api-key': clientId,
  };

  Future<List<TraktNextUpItem>> getNextUp({int limit = 50}) async {
    final url = Uri.parse('$baseUrl/sync/watched/shows?limit=$limit');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => TraktNextUpItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch next up');
    }
  }

  Future<TraktShowProgress> fetchShowProgress(int traktId) async {
    final url = Uri.parse('$baseUrl/shows/$traktId/progress/watched');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch progress');
    }

    return TraktShowProgress.fromJson(jsonDecode(res.body));
  }

  Future<List<TraktHistoryItem>> getWatchHistory({int limit = 50}) async {
    final url = Uri.parse('$baseUrl/sync/history?limit=$limit');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => TraktHistoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch watch history');
    }
  }

  Future<List<dynamic>> getWatchedShows({int limit = 50, int page = 1}) async {
    final url = Uri.parse('$baseUrl/sync/watched/shows?limit=$limit&page=$page');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch watched shows: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<dynamic>> getWatchedMovies({int limit = 50, int page = 1}) async {
    final url = Uri.parse('$baseUrl/sync/watched/movies?limit=$limit&page=$page');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch watched movies: ${res.statusCode} ${res.body}');
    }
  }
}
