import 'dart:convert';

import 'package:petal/api/query_proxy.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/resource.dart';

class Addon {
  final String id;
  final String userId;
  final String manifestUrl;
  final String baseUrl;
  Map<String, dynamic>? manifest;
  final Set<String> enabledResources;
  final int forced;

  Addon({
    required this.id,
    required this.userId,
    required this.manifestUrl,
    required this.baseUrl,
    this.manifest,
    Set<String>? enabledResources,
    required this.forced,
  }) : enabledResources = enabledResources ?? {};

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: json['id'],
      userId: json['user_id'],
      manifestUrl: json['manifest_url'],
      baseUrl: json['manifest_url'].replaceAll('/manifest.json', ''),
      enabledResources: Set<String>.from(json['resources']),
      forced: json['forced'] ?? 0,
    );
  }

  Future<void> fetchManifest() async {
    try {
      final response = await BackendApi.dio.get(QueryProxy.wrap(manifestUrl));
      if (response.statusCode != 200) return;

      final data = response.data;
      if (data is Map<String, dynamic>) {
        manifest = data;
      } else if (data is Map) {
        manifest = Map<String, dynamic>.from(data);
      } else if (data is String) {
        manifest = jsonDecode(data) as Map<String, dynamic>;
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
