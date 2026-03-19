import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';

class ApiCache {
  static Future<List<Addon>>? _addonsFuture;
  static final Map<String, Future<List<CatalogItem>>> _catalogItemsFuture = {};
  static final Map<String, List<Catalog>> _catalogs = {};

  static Future<List<Addon>> getAddons() {
    _addonsFuture ??= TraktApi.fetchUserAddons();
    return _addonsFuture!;
  }

  static void refreshAddons() {
    _addonsFuture = TraktApi.fetchUserAddons();
  }

  static List<Catalog> getCatalogs(Addon addon) {
    _catalogs[addon.id] ??= Api.generateCatalogs(addon);
    return _catalogs[addon.id]!;
  }

  static Future<List<CatalogItem>> getCatalogItems(Catalog catalog) {
    _catalogItemsFuture[catalog.id + catalog.type] ??= CatalogApi.fetchCatalogItems(catalog);
    return _catalogItemsFuture[catalog.id + catalog.type]!;
  }
}
