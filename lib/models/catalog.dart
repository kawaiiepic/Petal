class Catalog {
  final String name; // "Popular", "New", etc
  final String type; // movie, series
  final String id; // top, year, imdbRating
  final List<CatalogExtra> extra;
  final String url;

  Catalog({required this.name, required this.type, required this.id, this.extra = const [], required this.url});

  // Factory constructor to create Catalog from JSON
  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      extra: (json['extra'] as List<dynamic>?)?.map((e) => CatalogExtra.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class CatalogExtra {
  final String name;
  final List<String> options;

  CatalogExtra({required this.name, required this.options});

  // Factory constructor to create CatalogExtra from JSON
  factory CatalogExtra.fromJson(Map<String, dynamic> json) {
    return CatalogExtra(name: json['name'] ?? '', options: (json['options'] as List<dynamic>?)?.map((o) => o.toString()).toList() ?? []);
  }
}
