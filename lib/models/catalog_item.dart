import 'package:blssmpetal/models/catalog.dart';

class CatalogItem {
  final Catalog catalog;
  final String id;
  final String name;
  final String poster;
  final String background;

  CatalogItem({required this.catalog, required this.id, required this.name, required this.poster, this.background = ''});

  factory CatalogItem.fromJson(Map<String, dynamic> json, catalog) {
    return CatalogItem(catalog: catalog, id: json['id'], name: json['name'], poster: json['poster'] ?? '', background: json['background'] ?? '');
  }
}
