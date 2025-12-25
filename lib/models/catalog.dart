class Catalog {
  final String name; // "Popular", "New", etc
  final String type; // movie, series
  final String id; // top, year, imdbRating
  final List<CatalogExtra> extras;
  final String url;

  Catalog({required this.name, required this.type, required this.id, this.extras = const [], required this.url});
}

class CatalogExtra {
  final String name;
  final List<String> options;

  CatalogExtra({required this.name, required this.options});
}
