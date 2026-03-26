import 'dart:typed_data';

import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/tmdb/tmdb_models.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';

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

  static Future<Uint8List> getTmdbPoster(String mediaType, String tmdbId) {
    return _tmdbPosterFuture.putIfAbsent(mediaType + tmdbId, () => TMDB.poster(MediaType.user.fromTmdbSafe(mediaType), tmdbId));
  }

  static Future<Uint8List> getTmdbStill(String tmdbId, TraktEpisode episode) {
    return _tmdbStillFuture.putIfAbsent(tmdbId + episode.title!, () => TMDB.still(tmdbId, episode.season, episode.number));
  }

  static Future<TmdbSearchResult> getTmdbSearch(String imdbId) {
    return _tmdbSearchResult.putIfAbsent(imdbId , () => TMDB.search(imdbId));
  }

  static Future<List<TraktWatchedShowWithProgress>> getTraktWatched() {
    _watchedShowWithProgressFuture ??= TraktApi.fetchWatchedShowWithProgress();
    return _watchedShowWithProgressFuture!;
  }
}
