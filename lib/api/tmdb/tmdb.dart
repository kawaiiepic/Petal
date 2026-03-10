import 'dart:convert';
import 'dart:io';

import 'package:blssmpetal/api/tmdb/tmdb_models.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TMDB {
  static Map<String, Future<Uint8List>> imageData = {};
  static String accessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OTA3MDBmYWY5ZDZmYzMwMWMxM2Y0MWUzMTIxZDU1YSIsIm5iZiI6MTU5OTIxMDQ4My41NTIsInN1YiI6IjVmNTIwM2YzYjIzNGI5MDAzNzE4YjMzNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.RHJTrJPzXmpf0GM6FB8gdipG46lSo-XFY3FQ_Ljjy2c';

  static Map<String, String> get _headers => {'accept': 'application/json', 'Authorization': 'Bearer $accessToken'};

  static Future<Uint8List> poster(MediaType mediaType, String id) {
    if (imageData.containsKey(id)) {
      return imageData[id]!;
    } else {
      return imageData[id] = _poster(mediaType, id);
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
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/cache/tmdb/$tmdb.jpg');

    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      return imageData[tmdb] = Future.value(bytes);
    } else {
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
          var art = await http.get(Uri.parse('https://image.tmdb.org/t/p/original${images.posters![0].filePath!}'));
          file.createSync(recursive: true);
          file.writeAsBytes(art.bodyBytes);

          return art.bodyBytes;
        } else {
          return Future.error(Exception('Missing Poster'));
        }
      } else {
        return Future.error(Exception());
      }
    }
  }
}
