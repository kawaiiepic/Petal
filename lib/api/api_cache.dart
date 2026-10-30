import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/cache/async_cache.dart';
import 'package:petal/api/catalog_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/tmdb/tmdb_search_result.dart';

class ApiCache {
  static Future<List<Addon>>? _addonsFuture;
  static final Map<String, Future<List<CatalogItem>>> _catalogItemsFuture = {};
  static final _tmdbSearchResult = AsyncCache<String, TmdbSearchResult>(
    ttl: const Duration(hours: 6),
  );

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
    return _catalogItemsFuture.putIfAbsent(
      catalog.id + catalog.type,
      () => CatalogApi.fetchCatalogItems(catalog),
    );
  }

  static Future<TmdbSearchResult> getTmdbSearch(String imdbId) {
    return _tmdbSearchResult.get(imdbId, () => TMDB.search(imdbId));
  }
}
