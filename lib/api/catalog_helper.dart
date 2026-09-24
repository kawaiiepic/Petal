import 'dart:convert';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/connection_error.dart';
import 'package:http/http.dart' as http;

class CatalogApi {
  static final Map<Uri, List<CatalogItem>> _cache = {};

  static void clearCache() {
    _cache.clear();
  }

  static Future<List<CatalogItem>> fetchCatalogItems(Catalog catalog, {Map<String, String>? filters}) async {
    final uri = Uri.parse(catalog.url).replace(queryParameters: filters);
    if (_cache.containsKey(uri)) {
      return _cache[uri]!;
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw ConnectionException('Failed to fetch catalog (${response.statusCode}).');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['metas'] as List).map((e) => CatalogItem.fromJson(e)).toList();

      _cache[uri] = items;
      return items;
    } on ConnectionException {
      rethrow;
    } catch (e) {
      throw ConnectionException('Could not reach ${catalog.name}.');
    }
  }
}
