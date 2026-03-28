import 'dart:async';

import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class Api {
  static bool dev = true;
  static bool traktLoggedIn = false;
  static bool loggedIn = false;

  static String proxyImage(String url) {
    return "$ServerUrl/img?url=${Uri.encodeComponent(url)}";
  }

  static final ServerUrl = dev ? 'http://localhost:3000' : 'https://petal.blossomvale.dev/api';

  static final ValueNotifier<bool> healthy = ValueNotifier(true);

  static Future<void> initApi() async {
    await TraktApi.init();
    await TraktApi.verifySession();

    if (TraktApi.validSession.value) {
      _onBackendRecovered();
    }

    // initial check
    final ok = await healthCheck();
    healthy.value = ok;
  }

  static void _onBackendRecovered() {
    CatalogApi.clearCache();
  }

  static Future<bool> healthCheck() async {
    try {
      final res = await TraktApi.dio.get("$ServerUrl/health").timeout(const Duration(seconds: 3));

      return res.statusCode == 200;
    } catch (_) {
      return false;
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
      print("Running catalog");
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
