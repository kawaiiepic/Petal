import 'dart:async';

import 'package:petal/api/catalog_helper.dart';
import 'package:petal/api/trakt/trakt_helper.dart';
import 'package:petal/main.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/settings.dart';
import 'package:flutter/material.dart';

class Api {
  static bool traktLoggedIn = false;
  static bool devMode = false;

  static String proxyImage(String url) {
    return "$ServerUrl/img?url=${Uri.encodeComponent(url)}";
  }

  static final ServerUrl = devMode ? 'http://localhost:8787' : 'https://petal-backend.blossomvale.dev';

  static final ValueNotifier<bool> healthy = ValueNotifier(false);
  static Timer? healthyTimer;

  static Future<void> initApi() async {
    await TraktApi.init();
    // initial check
    healthyTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      healthCheck();

      healthyTimer?.cancel();
    });

    healthy.addListener(() {});
  }

  static Future<void> _onBackendRecovered() async {
    if (await TraktApi.verifySession()) {
      TraktApi.authState.setLoggedIn(true);
    }
    CatalogApi.clearCache();
  }

  static Future<bool> healthCheck() async {
    print("Health check./..");
    try {
      final res = await TraktApi.dio.get("$ServerUrl/health").timeout(const Duration(seconds: 3));

      _onBackendRecovered();

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static bool isMobile() {
    var shortestSide = MediaQuery.sizeOf(PetalApp.rootNavigatorKey.currentContext!).shortestSide;
    return shortestSide < 550;
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

      catalogs.add(Catalog(name: cat['name'], type: type, id: id, extra: extras, url: '$baseUrl/catalog/$type/$id.json'));
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
