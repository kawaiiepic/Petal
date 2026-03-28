import 'dart:convert';
import 'dart:io';
import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/tmdb/tmdb_models.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TMDB {
  static Map<String, Future<Uint8List>> imageData = {};
  static const apiUrl = 'api.themoviedb.org';
  static const imageUrl = 'https://image.tmdb.org/t/p/w500';

  static String accessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OTA3MDBmYWY5ZDZmYzMwMWMxM2Y0MWUzMTIxZDU1YSIsIm5iZiI6MTU5OTIxMDQ4My41NTIsInN1YiI6IjVmNTIwM2YzYjIzNGI5MDAzNzE4YjMzNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.RHJTrJPzXmpf0GM6FB8gdipG46lSo-XFY3FQ_Ljjy2c';

  static Map<String, String> get _headers => {'accept': 'application/json', 'Authorization': 'Bearer $accessToken'};

  static Uri apiCall(String url) {
    return Uri.parse("${Api.ServerUrl}/tmdb?url=$url");
  }

  static Future<TmdbSearchResult> search(String searchedId) async {
    print("Searching $searchedId");
    final response = await http.get(apiCall('/find/$searchedId?external_source=imdb_id'), headers: _headers);

    if (response.statusCode != 200) throw Exception('Search failed');

    return TmdbSearchResult.fromJson(jsonDecode(response.body));
  }

  static Future<TmdbEpisode> tvEpisode(int tmdbId, int seasonNumber, int episodeNumber) async {
    final response = await http.get(apiCall('/tv/$tmdbId/season/$seasonNumber/episode/$episodeNumber'), headers: _headers);

    if (response.statusCode != 200) throw Exception('Search failed');

    return TmdbEpisode.fromJson(jsonDecode(response.body));
  }

    static Future<TmdbSeason> tvSeason(int tmdbId, int seasonNumber) async {
    final response = await http.get(apiCall('/tv/$tmdbId/season/$seasonNumber'), headers: _headers);

    if (response.statusCode != 200) throw Exception('Search failed');

    return TmdbSeason.fromJson(jsonDecode(response.body));
  }

  static Future<TmdbShow> tvShow(int tmdbId) async {
    final response = await http.get(apiCall('/tv/$tmdbId?append_to_response=images,external_ids'), headers: _headers);

    if (response.statusCode != 200) throw Exception('Search failed');

    return TmdbShow.fromJson(jsonDecode(response.body));
  }

  static Future<TmdbMovie> movie(int tmdbId) async {
    final response = await http.get(apiCall('/movie/$tmdbId?append_to_response=images,external_ids'), headers: _headers);

    if (response.statusCode != 200) throw Exception('Search failed');

    return TmdbMovie.fromJson(jsonDecode(response.body));

  }

  // Old Functions...

  static Future<Uint8List> poster(MediaType mediaType, String id) {
    if (imageData.containsKey("poster_$id")) {
      print("Loading poster from cache");
      return imageData["poster_$id"]!;
    } else {
      return imageData["poster_$id"] = _poster(mediaType, id);
    }
  }

  static Future<Uint8List> still(String id, int season, int episode) {
    if (imageData.containsKey("still_${id}_${season}_$episode")) {
      return imageData["still_${id}_${season}_$episode"]!;
    } else {
      return imageData["still_${id}_${season}_$episode"] = _episode_still(id, season, episode);
    }
  }

  static Future<Uint8List> backdrop(String tmdbId) {
    if (imageData.containsKey("backdrop$tmdbId")) {
      print("Loading backdrop from cache");
      return imageData["backdrop$tmdbId"]!;
    } else {
      return imageData["backdrop$tmdbId"] = _movieBackdrop(tmdbId);
    }
  }

  static Future<String> posterUrl(MediaType mediaType, String tmdb) async {
    Uri url = Uri();
    if (mediaType == MediaType.show) {
      url = Uri.https('api.themoviedb.org', '/3/tv/$tmdb/images', {'language': 'en'});
    } else if (mediaType == MediaType.movie) {
      url = Uri.https('api.themoviedb.org', '/3/movie/$tmdb/images', {'language': 'en'});
    }

    var response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      var images = Images.fromJson(jsonDecode(response.body));

      if (images.posters != null && images.posters!.isNotEmpty) {
        return 'https://image.tmdb.org/t/p/original${images.posters![0].filePath!}';
      } else {
        throw Exception();
      }
    } else {
      throw Future.error(Exception);
    }
  }

  static Future<Uint8List> _poster(MediaType mediaType, String tmdb) async {
    File? file;
    if (kIsWeb) {
    } else {
      final directory = await getApplicationCacheDirectory();
      file = File('${directory.path}/cache/tmdb/poster_$tmdb.jpg');

      // check disk cache first
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return bytes;
      }
    }

    final path = mediaType == MediaType.show ? '/3/tv/$tmdb/images' : '/3/movie/$tmdb/images';
    final url = Uri.https('api.themoviedb.org', path, {'language': 'en'});

    final response = await http.get(url, headers: _headers);
    if (response.statusCode != 200) return Future.error(Exception('Failed: ${response.statusCode}'));

    final images = Images.fromJson(jsonDecode(response.body));
    if (images.posters == null || images.posters!.isEmpty) return Future.error(Exception('No posters'));

    final art = await http.get(Uri.parse(Api.proxyImage('https://image.tmdb.org/t/p/w500${images.posters![0].filePath!}')));
    // use w500 instead of original — much smaller file, plenty for a poster thumbnail

    if (!kIsWeb && file != null) {
      await file.create(recursive: true); // use async version
      await file.writeAsBytes(art.bodyBytes);
    }

    return art.bodyBytes;
  }

  static Future<Uint8List> _movieBackdrop(String tmdbId) async {
    File? file;

    if (kIsWeb) {
    } else {
      final directory = await getApplicationCacheDirectory();
      file = File('${directory.path}/cache/tmdb/backdrop_$tmdbId.jpg');

      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }

    final url = Uri.https('api.themoviedb.org', '/3/movie/$tmdbId/images');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode != 200) return Future.error(Exception('Failed: ${response.statusCode}'));

    final images = Images.fromJson(jsonDecode(response.body));
    if (images.backdrops == null || images.backdrops!.isEmpty) return Future.error(Exception('No Backdrops'));

    print("Getting this image: ${'https://image.tmdb.org/t/p/original${images.backdrops![0].filePath!}'}");

    final art = await http.get(Uri.parse(Api.proxyImage('https://image.tmdb.org/t/p/original${images.backdrops![0].filePath!}')));
    // w780 is ideal for episode stills — good quality without being huge

    if (!kIsWeb && file != null) {
      await file.create(recursive: true);
      await file.writeAsBytes(art.bodyBytes);
    }

    return art.bodyBytes;
  }

  static Future<Uint8List> _episode_still(String tmdb, int season, int episode) async {
    File? file;
    if (kIsWeb) {
    } else {
      final directory = await getApplicationCacheDirectory();
      file = File('${directory.path}/cache/tmdb/still_${season}_${episode}_$tmdb.jpg');

      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }

    final url = Uri.https('api.themoviedb.org', '/3/tv/$tmdb/season/$season/episode/$episode/images');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode != 200) return Future.error(Exception('Failed: ${response.statusCode}'));

    final images = Images.fromJson(jsonDecode(response.body));
    if (images.stills == null || images.stills!.isEmpty) return Future.error(Exception('No stills'));

    print("Getting this image: ${'https://image.tmdb.org/t/p/original${images.stills![0].filePath!}'}");

    final art = await http.get(Uri.parse(Api.proxyImage('https://image.tmdb.org/t/p/original${images.stills![0].filePath!}')));
    // w780 is ideal for episode stills — good quality without being huge

    if (!kIsWeb && file != null) {
      await file.create(recursive: true);
      await file.writeAsBytes(art.bodyBytes);
    }

    return art.bodyBytes;
  }
}
