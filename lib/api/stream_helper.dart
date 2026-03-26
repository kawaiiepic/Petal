import 'dart:convert';
import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/custom_model.dart';
import 'package:blssmpetal/models/stremio/stremio_episode.dart';
import 'package:http/http.dart' as http;

import 'package:blssmpetal/models/stream.dart';

class StreamApi {
  static Future<List<StreamItem>> fetchStreams(String imdbId, Episode? episode) async {
    final addons = await ApiCache.getAddons();
    final streamAddons = addons.where((a) => a.enabledResources.contains('stream')).toList();

    final type = episode != null ? 'series' : 'movie';
    final id = episode != null ? '$imdbId:${episode.seasonNumber}:${episode.episodeNumber}' : imdbId;

    print("Fetching stream");

    // Fetch all addons in parallel
    final results = await Future.wait(streamAddons.map((addon) => _fetchFromAddon(addon, type, id, episode)));



    final expanded = results.expand((s) => s).toList();

    if (expanded.isEmpty) {
      print("No Streams found");
    }

    return expanded;
  }

  static Future<List<StreamItem>> _fetchFromAddon(Addon addon, String type, String id, Episode? episode) async {
    try {
      final url = '${addon.baseUrl}/stream/$type/$id.json';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];

      final streams = (jsonDecode(res.body)['streams'] as List? ?? []).map((s) => StreamItem.fromJson(s, addon)).toList();

      if (episode == null) return streams;

      final tag = 'S${episode.seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')}';
      return streams
          .where((s) => s.season == episode.seasonNumber && s.episode == episode.episodeNumber || s.name.toUpperCase().contains(tag) || s.external)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static StreamItem? autoSelectStream(List<StreamItem> streams) {
    if (streams.isEmpty) return null;

    print("Auto selecting stream");

    // sort by score descending, pick the top one
    final sorted = [...streams]..sort((a, b) => _score(b).compareTo(_score(a)));

    print("Selected: ${sorted.first.title}");
    return sorted.first;
  }

  static int _score(StreamItem s) {
    int score = 0;

    final name = s.name.toUpperCase();

    // Resolution
    if (name.contains('2160P') || name.contains('4K'))
      score += 40;
    else if (name.contains('1080P'))
      score += 30;
    else if (name.contains('720P'))
      score += 20;
    else if (name.contains('480P'))
      score += 10;

    // Source quality
    if (name.contains('BLURAY') || name.contains('BLU-RAY'))
      score += 15;
    else if (name.contains('WEB-DL') || name.contains('WEBDL'))
      score += 12;
    else if (name.contains('WEBRIP'))
      score += 10;
    else if (name.contains('HDRIP'))
      score += 8;

    if (name.contains("WEB")) score += 20;

    // HDR
    if (name.contains('HDR') || name.contains('DOLBY')) score += 5;

    // Penalize CAM/TS
    if (name.contains('CAM') || name.contains('.TS')) score -= 30;

    if (name.contains('⚡')) score += 30;

    // Prefer non-external (direct play)
    if (!s.external) score += 5;

    print("${s.title} has score $score");

    return score;
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
