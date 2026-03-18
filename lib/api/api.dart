import 'dart:async';

import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Api {
  static bool dev = false;
  static bool traktLoggedIn = false;

  static String proxyImage(String url) {
    return "$ServerUrl/img?url=${Uri.encodeComponent(url)}";
  }

  static final ServerUrl = dev ? 'http://localhost:3000' : 'https://petal.blossomvale.dev/api';

  static final ValueNotifier<bool> healthy = ValueNotifier(true);
  static Timer? _healthPoller;

  static Future<List<Addon>?> addonsFuture = Future.value(null);

  static Future<void> initApi() async {
    await TraktApi.verifySession();

    _healthPoller?.cancel();

    if (TraktApi.validSession.value) {

      _onBackendRecovered();
    }

    // _healthPoller = Timer.periodic(const Duration(seconds: 60), (_) async {
    //   final ok = await healthCheck();

    //   if (healthy.value != ok) {
    //     healthy.value = ok;

    //     if (ok) {
    //       _onBackendRecovered();
    //     }
    //   }
    // });

    // initial check
    final ok = await healthCheck();
    healthy.value = ok;
  }

  static void _onBackendRecovered() {
    addonsFuture = TraktApi.fetchUserAddons();
    CatalogApi.clearCache();
  }

  static Future<bool> healthCheck() async {
    try {
      final res = await http.get(Uri.parse("$ServerUrl/health")).timeout(const Duration(seconds: 3));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Other
  //
  static var _generatedCatalogs = {};

  static List<Catalog> generateCatalogs(String baseUrl, String slug, Map<String, dynamic> manifest) {
    if (_generatedCatalogs[baseUrl + slug] != null) return _generatedCatalogs[baseUrl + slug]!;
    print("Generating Catalogs");
    final List<Catalog> catalogs = [];

    if (manifest['catalogs'] == null) return catalogs;

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

    _generatedCatalogs[baseUrl + slug] = catalogs;

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
