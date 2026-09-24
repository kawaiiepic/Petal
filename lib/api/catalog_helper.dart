import 'dart:convert';

import 'package:petal/api/query_proxy.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/connection_error.dart';

class CatalogApi {
  static final Map<Uri, List<CatalogItem>> _cache = {};

  static void clearCache() {
    _cache.clear();
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    throw const ConnectionException('Unexpected catalog response.');
  }

  static Future<List<CatalogItem>> fetchCatalogItems(Catalog catalog, {Map<String, String>? filters}) async {
    final uri = Uri.parse(catalog.url).replace(queryParameters: filters);
    if (_cache.containsKey(uri)) {
      return _cache[uri]!;
    }

    try {
      final response = await BackendApi.dio.get(QueryProxy.wrap(uri.toString()));

      if (response.statusCode != 200) {
        throw ConnectionException('Failed to fetch catalog (${response.statusCode}).');
      }

      final data = _asMap(response.data);
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
