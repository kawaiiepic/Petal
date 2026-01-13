import 'dart:convert';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:http/http.dart' as http;

class CatalogApi {
  /// Fetch items from a Cinemeta catalog URL.
  /// Optionally pass filters like genre, search, skip.
  static Future<List<CatalogItem>> fetchCatalogItems(Catalog catalog, {Map<String, String>? filters}) async {
    final uri = Uri.parse(catalog.url).replace(queryParameters: filters);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch catalog');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['metas'] as List).map((e) => CatalogItem.fromJson(e, catalog)).toList();
    
    return items;
  }
}
