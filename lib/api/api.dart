import 'dart:async';

import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/settings.dart';
import 'package:flutter/material.dart';

class Api {
  static bool dev = true;
  static bool traktLoggedIn = false;
  static bool loggedIn = false;

  static String proxyImage(String url) {
    return "$ServerUrl/img?url=${Uri.encodeComponent(url)}";
  }

  static final ServerUrl = dev ? 'http://10.0.0.105:3000' : 'https://petal.blossomvale.dev/api';

  static final ValueNotifier<bool> healthy = ValueNotifier(false);

  static Future<void> initApi() async {
    await TraktApi.init();
    // initial check

    healthy.addListener(() {
      print("Running healthy");
      if (healthy.value) {
        _onBackendRecovered();
      }
    });

    final ok = await healthCheck();
    healthy.value = ok;
  }

  static void _onBackendRecovered() {
    TraktApi.verifySession();
    CatalogApi.clearCache();
  }

  static Future<bool> healthCheck() async {
    try {
      final res = await TraktApi.dio.get("$ServerUrl/health").timeout(const Duration(seconds: 3));

      print(res.data);

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Settings?> userSettings() async {
    final response = await TraktApi.dio.get('${Api.ServerUrl}/user/settings');

    if (response.statusCode == 200) {
      return Settings.fromJson(response.data);
    } else {
      return null;
    }
  }

  static List<Catalog> generateCatalogs(Addon addon) {
    print("Generating Catalogs");
    final List<Catalog> catalogs = [];
    final manifest = addon.manifest!;

    if (manifest['catalogs'] == null) return catalogs;

    final baseUrl = addon.id == 'com.linvo.cinemeta' ? 'https://cinemeta-catalogs.strem.io' : addon.baseUrl;

    const allowed = {'top', 'year', 'imdbRating'};

    for (final cat in manifest['catalogs']) {
      final id = cat['id'];
      final type = cat['type'];
      if (!allowed.contains(id)) continue;

      final extras = <CatalogExtra>[];

      if (cat['extra'] is List) {
        for (final extra in cat['extra']) {
          extras.add(CatalogExtra(name: extra['name'], options: (extra['options'] as List?)?.map((e) => e.toString()).toList() ?? []));
        }
      }

      catalogs.add(Catalog(name: cat['name'], type: type, id: id, extra: extras, url: '$baseUrl/$id/catalog/$type/$id.json'));
    }

    return catalogs;
  }

  static String buildCatalogUrl({required String baseUrl, required String slug, required Catalog catalog, Map<String, String>? selectedExtras}) {
    var url = '$baseUrl/$slug/catalog/${catalog.type}/${catalog.id}.json';

    if (selectedExtras != null && selectedExtras.isNotEmpty) {
      final query = selectedExtras.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      url += '?$query';
    }

    return url;
  }
}
