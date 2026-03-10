import 'dart:convert';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
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
      final url = episode != null
          ? '$baseUrl/stream/${item.type}/${item.id}:${episode.season}:${episode.episode}.json'
          : '$baseUrl/stream/${item.type}/${item.id}.json';

      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        final streams = data['streams'] as List? ?? [];

        final mappedStreams = streams.map((s) => StreamItem.fromJson(s, addon)).toList();

        if (episode != null) {
          final tag = "S${episode.season.toString().padLeft(2, '0')}E${episode.episode.toString().padLeft(2, '0')}";
          allStreams.addAll(mappedStreams.where((s) => s.season == episode.season && s.episode == episode.episode || s.name.toUpperCase().contains(tag)));
        } else {
          allStreams.addAll(mappedStreams);
        }
      } catch (_) {}
    }

    return allStreams;
  }

  static Future<List<CatalogItem>> searchCatalogItems(String query, List<Addon> addons) async {
    final List<CatalogItem> allItems = [];
    final encodedQuery = Uri.encodeComponent(query);

    for (final addon in addons) {
      if (!addon.enabledResources.contains('catalog')) continue;

      final List<Catalog> catalogs = (addon.manifest?["catalogs"] as List<dynamic>?)?.map((c) => Catalog.fromJson(c as Map<String, dynamic>)).toList() ?? [];

      for (final Catalog catalog in catalogs) {
        // Only catalogs that support search
        final supportsSearch = catalog.extra.any((e) => e.name == 'search');
        if (!supportsSearch) continue;

        final url = '${addon.baseUrl}/catalog/${catalog.type}/${catalog.id}/search=$encodedQuery.json';

        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode != 200) continue;

          final data = jsonDecode(res.body);
          final metas = data['metas'] as List? ?? [];

          final items = metas.map((m) => CatalogItem.fromJson(m));

          allItems.addAll(items);
        } catch (_) {
          print("Exception!!");
        }
      }
    }
    return allItems;
  }

  static Future<CatalogItem?> fetchCatalogItemById(String id, String type, {String baseUrl = 'https://v3-cinemeta.strem.io/meta'}) async {
    final url = '$baseUrl/$type/$id.json';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CatalogItem.fromJson(data['meta']);
    } catch (e) {
      print('Error fetching CatalogItem $id: $e');
      return null;
    }
  }

  static Future<CatalogItem?> fetchCatalogItem(CatalogItem item, {String baseUrl = 'https://v3-cinemeta.strem.io/meta'}) async {
    final url = '$baseUrl/${item.type}/${item.id}.json';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CatalogItem.fromJson(data['meta']);
    } catch (e) {
      print('Error fetching CatalogItem ${item.id}: $e');
      return null;
    }
  }
}
