class CatalogExtra {
  final String name;
  final List<String> options;

  CatalogExtra({required this.name, required this.options});

  factory CatalogExtra.fromJson(Map<String, dynamic> json) {
    return CatalogExtra(
      name: json['name'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((option) => option.toString())
              .toList() ??
          [],
    );
  }
}
