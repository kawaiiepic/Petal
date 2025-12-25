import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Api {
  static const ServerUrl = 'http://localhost:3000';
  static late Future<List<Addon>> addonsFuture;

  static Future<void> initApi() async {
    addonsFuture = Api.fetchUserAddons('mia');
  }

  static Future<bool> canPingServer() async {
    return false;
  }

  // Other
  static List<Catalog> generateCatalogs(String baseUrl, String slug, Map<String, dynamic> manifest) {
    final List<Catalog> catalogs = [];

    if (manifest['catalogs'] == null) return catalogs;

    const allowed = {'top', 'year', 'imdbRating'};

    for (final cat in manifest['catalogs']) {
      final id = cat['id'];
      final type = cat['type'];
      if (!allowed.contains(id)) continue;

      final extras = <CatalogExtra>[];

      if (cat['extra'] is List) {
        for (final extra in cat['extra']) {
          extras.add(CatalogExtra(name: extra['name'], options: (extra['options'] as List?)?.map((e) => e.toString()).toList() ?? []));
        }
      }

      catalogs.add(Catalog(name: cat['name'], type: type, id: id, extras: extras, url: '$baseUrl/$id/catalog/$type/$id.json'));
    }

    return catalogs;
  }

  static String buildCatalogUrl({required String baseUrl, required String slug, required Catalog catalog, Map<String, String>? selectedExtras}) {
    var url = '$baseUrl/$slug/catalog/${catalog.type}/${catalog.id}.json';

    if (selectedExtras != null && selectedExtras.isNotEmpty) {
      final query = selectedExtras.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      url += '?$query';
    }

    return url;
  }

  // Private Server
  static Future<List<Addon>> fetchUserAddons(String userId) async {
    final url = '$ServerUrl/addons/$userId'; // your server URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final addonsJson = data['addons'] as List;

      // map to list of futures
      final futures = addonsJson.map((json) async {
        var addon = Addon.fromJson(json);
        await addon.fetchManifest(); // now allowed
        return addon;
      }).toList();

      // wait for all futures to complete
      final addons = await Future.wait(futures);
      return addons;
    } else {
      throw Exception('Failed to fetch addons');
    }
  }
}
