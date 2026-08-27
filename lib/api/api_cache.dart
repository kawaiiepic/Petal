import 'dart:typed_data';

import 'package:petal/api/api.dart';
import 'package:petal/api/catalog_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/models.dart';
import 'package:petal/api/trakt/trakt_class.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';

class ApiCache {
  static Future<List<Addon>>? _addonsFuture;
  static final Map<String, Future<List<CatalogItem>>> _catalogItemsFuture = {};
  static final Map<String, Future<Search>> _searchFuture = {};
  static final Map<String, Future<Uint8List>> _tmdbPosterFuture = {};
  static final Map<String, Future<Uint8List>> _tmdbStillFuture = {};
  static final Map<String, Future<TmdbSearchResult>> _tmdbSearchResult = {};
  static Future<List<TraktWatchedShowWithProgress>>? _watchedShowWithProgressFuture;

  static final Map<String, List<Catalog>> _catalogs = {};

  static Future<List<Addon>> getAddons() {
    _addonsFuture ??= BackendApi.fetchUserAddons();
    return _addonsFuture!;
  }

  static void refreshAddons() {
    _addonsFuture = BackendApi.fetchUserAddons();
  }

  static List<Catalog> getCatalogs(Addon addon) {
    return _catalogs.putIfAbsent(addon.id, () => Api.generateCatalogs(addon));
  }

  static Future<List<CatalogItem>> getCatalogItems(Catalog catalog) {
    return _catalogItemsFuture.putIfAbsent(catalog.id + catalog.type, () => CatalogApi.fetchCatalogItems(catalog));
  }

  static Future<TmdbSearchResult> getTmdbSearch(String imdbId) {
    return _tmdbSearchResult.putIfAbsent(imdbId, () => TMDB.search(imdbId));
  }
}
