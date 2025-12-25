import 'dart:convert';

import 'package:blssmpetal/models/resource.dart';
import 'package:http/http.dart' as http;

class Addon {
  final String id;
  final String name;
  final String manifestUrl;
  final String baseUrl;
  Map<String, dynamic>? manifest; // full manifest JSON, may contain logo/icon
  // user state
  final Set<String> enabledResources;

  Addon({required this.id, required this.name, required this.manifestUrl, required this.baseUrl, this.manifest, Set<String>? enabledResources})
    : enabledResources = enabledResources ?? {};

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(id: json['id'], name: json['name'], manifestUrl: json['manifestUrl'], baseUrl: json['manifestUrl'].replaceAll('/manifest.json', ''), enabledResources: Set<String>.from(json['enabledResources'] ?? []));
  }

  // async method to fetch manifest
  Future<void> fetchManifest() async {
    try {
      final response = await http.get(Uri.parse(manifestUrl));
      if (response.statusCode == 200) {
        manifest = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching manifest for $id: $e');
    }
  }

  List<AddonResource> get resources {
    final raw = manifest?['resources'];
    if (raw is! List) return [];

    return raw.map((r) => AddonResource.fromJson(r)).toList();
  }
}
