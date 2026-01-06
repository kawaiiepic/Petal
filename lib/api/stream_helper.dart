import 'dart:convert';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/episode.dart';
import 'package:http/http.dart' as http;

import 'package:blssmpetal/models/stream.dart';

class StreamApi {
  static Future<List<StreamItem>> fetchStreams(CatalogItem item, List<Addon> addons, {Episode? episode}) async {
    final List<StreamItem> allStreams = [];

    for (final addon in addons) {
      if (!addon.enabledResources.contains('stream')) continue;
      final baseUrl = addon.baseUrl; // you should already have this
      final url = episode != null ? '$baseUrl/stream/${item.catalog.type}/${item.id}:${episode.season}:${episode.episode}.json' : '$baseUrl/stream/${item.catalog.type}/${item.id}.json';

      print(url);

      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        final streams = data['streams'] as List? ?? [];

        final mappedStreams = streams.map((s) => StreamItem.fromJson(s, addon)).toList();

        if (episode != null) {
          final tag = "S${episode.season.toString().padLeft(2, '0')}E${episode.episode.toString().padLeft(2, '0')}";
          for (var s in mappedStreams) {print("Season: " + s.season.toString());}
          allStreams.addAll(mappedStreams.where((s) => s.season == episode.season && s.episode == episode.episode || s.name.toUpperCase().contains(tag)));
        } else {
          allStreams.addAll(mappedStreams);
        }
      } catch (_) {}
    }

    return allStreams;
  }
}
