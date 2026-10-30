import 'catalog_extra.dart';

export 'catalog_extra.dart';

class Catalog {
  final String name;
  final String type;
  final String id;
  final List<CatalogExtra> extra;
  final String url;

  Catalog({
    required this.name,
    required this.type,
    required this.id,
    this.extra = const [],
    required this.url,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      extra: (json['extra'] as List<dynamic>?)
              ?.map((item) => CatalogExtra.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
