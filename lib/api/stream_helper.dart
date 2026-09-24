import 'dart:convert';

import 'package:petal/api/api_cache.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/custom_model.dart';
import 'package:http/http.dart' as http;

import 'package:petal/models/stream.dart';
import 'package:petal/widgets/connection_error.dart';

class StreamApi {
  static Future<List<StreamItem>> fetchStreams(String imdbId, Episode? episode) async {
    final addons = await ApiCache.getAddons();
    addons.forEach((addon) {
      print(addon.enabledResources);
    });
    final streamAddons = addons.where((a) => a.enabledResources.contains('stream')).toList();

    final type = episode != null ? 'series' : 'movie';
    final id = episode != null ? '$imdbId:${episode.seasonNumber}:${episode.episodeNumber}' : imdbId;

    print("Fetching stream: ${streamAddons.length} addons");

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

      print(url);

      final res = await BackendApi.dio.get(url).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) return [];

      final streams = (res.data['streams'] as List? ?? []).map((s) => StreamItem.fromJson(s, addon)).toList();

      return streams;
    } catch (_) {
      return [];
    }
  }

  static StreamItem? streamFromUrl(List<StreamItem> streams, String url) {
    if (streams.isEmpty) return null;

    return streams.firstWhere((s) {
      if (s.url == url) return true;
      return false;
    });
  }

  static StreamItem? autoSelectStream(List<StreamItem> streams) {
    if (streams.isEmpty) return null;

    print("Auto selecting stream");

    final sorted = [...streams]..sort((a, b) => _score(b).compareTo(_score(a)));

    print("Selected: ${sorted.first.title}");
    return sorted.first;
  }

  static int _score(StreamItem s) {
    int score = 0;

    final name = s.name.toUpperCase();

    if (name.contains('2160P') || name.contains('4K')) {
      score += 40;
    } else if (name.contains('1080P'))
      score += 30;
    else if (name.contains('720P'))
      score += 20;
    else if (name.contains('480P'))
      score += 10;

    if (name.contains('BLURAY') || name.contains('BLU-RAY')) {
      score += 15;
    } else if (name.contains('WEB-DL') || name.contains('WEBDL'))
      score += 12;
    else if (name.contains('WEBRIP'))
      score += 10;
    else if (name.contains('HDRIP'))
      score += 8;

    if (name.contains("WEB")) score += 20;

    if (name.contains('HDR') || name.contains('DOLBY')) score += 5;

    if (name.contains('CAM') || name.contains('.TS')) score -= 30;

    if (name.contains('⚡')) score += 30;

    if (!s.external) score += 5;

    return score;
  }

  static Future<List<CatalogItem>> searchCatalogItems(String query, List<Addon> addons) async {
    final List<CatalogItem> allItems = [];
    final encodedQuery = Uri.encodeComponent(query);
    var attempted = 0;
    var failed = 0;

    for (final addon in addons) {
      if (!addon.enabledResources.contains('catalog')) continue;

      final List<Catalog> catalogs = (addon.manifest?["catalogs"] as List<dynamic>?)?.map((c) => Catalog.fromJson(c as Map<String, dynamic>)).toList() ?? [];

      for (final Catalog catalog in catalogs) {
        final supportsSearch = catalog.extra.any((e) => e.name == 'search');
        if (!supportsSearch) continue;

        final url = '${addon.baseUrl}/catalog/${catalog.type}/${catalog.id}/search=$encodedQuery.json';
        attempted++;

        try {
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) {
            failed++;
            continue;
          }

          final data = jsonDecode(res.body);
          final metas = data['metas'] as List? ?? [];
          allItems.addAll(metas.map((m) => CatalogItem.fromJson(m)));
        } catch (e) {
          failed++;
          print('Search request failed: $e');
        }
      }
    }

    if (allItems.isEmpty && attempted > 0 && failed == attempted) {
      throw const ConnectionException('Could not reach any catalog addon.');
    }

    return allItems;
  }

  static Future<CatalogItem?> fetchCatalogItemById(String id, String type, {String baseUrl = 'https://v3-cinemeta.strem.io/meta'}) async {
    final url = '$baseUrl/$type/$id.json';
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CatalogItem.fromJson(data['meta']);
    } catch (e) {
      print('Error fetching CatalogItem $id: $e');
      throw ConnectionException('Could not load this title.');
    }
  }

  static Future<CatalogItem?> fetchCatalogItem(CatalogItem item, {String baseUrl = 'https://v3-cinemeta.strem.io/meta'}) async {
    return fetchCatalogItemById(item.id, item.type, baseUrl: baseUrl);
  }
}
