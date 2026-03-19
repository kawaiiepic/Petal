import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';

class ApiCache {
  static Future<List<Addon>>? _addonsFuture;
  static final Map<String, Future<List<CatalogItem>>> _catalogItemsFuture = {};
  static final Map<String, Future<Search>> _searchFuture = {};

  static final Map<String, List<Catalog>> _catalogs = {};


  static Future<List<Addon>> getAddons() {
    _addonsFuture ??= TraktApi.fetchUserAddons();
    return _addonsFuture!;
  }

  static void refreshAddons() {
    _addonsFuture = TraktApi.fetchUserAddons();
  }

  static List<Catalog> getCatalogs(Addon addon) {
    return _catalogs.putIfAbsent(addon.id, () => Api.generateCatalogs(addon));
  }

  static Future<List<CatalogItem>> getCatalogItems(Catalog catalog) {
    return _catalogItemsFuture.putIfAbsent(catalog.id + catalog.type, () => CatalogApi.fetchCatalogItems(catalog));
  }

  static Future<Search> getSearch(String idType, String id, String type) {
    return _searchFuture.putIfAbsent(idType + id + type, () => TraktApi.search(idType, id, type));
  }
}
