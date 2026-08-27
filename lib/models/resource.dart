class AddonResource {
  final String name;
  final List<String>? types;

  AddonResource({required this.name, this.types});

  factory AddonResource.fromJson(dynamic json) {
    if (json is String) {
      return AddonResource(name: json);
    }

    if (json is Map<String, dynamic>) {
      return AddonResource(name: json['name'], types: json['types'] != null ? List<String>.from(json['types']) : null);
    }

    throw Exception('Unknown resource format');
  }
}
