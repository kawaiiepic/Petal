import 'dart:convert';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:http/http.dart' as http;

import 'package:blssmpetal/models/stream.dart';

class StreamApi {
  static Future<List<StreamItem>> fetchStreams(CatalogItem item, List<Addon> addons) async {
    final List<StreamItem> allStreams = [];

    for (final addon in addons) {
      if (!addon.enabledResources.contains('stream')) continue;
      final baseUrl = addon.baseUrl; // you should already have this
      final url = '$baseUrl/stream/${item.catalog.type}/${item.id}.json';

      print(url);

      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        final streams = data['streams'] as List?;

        if (streams == null) continue;

        allStreams.addAll(streams.map((s) => StreamItem.fromJson(s, addon)));
      } catch (_) {}
    }

    return allStreams;
  }
}
