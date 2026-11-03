import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/cache/async_cache.dart';
import 'package:petal/models/media_type.dart';

class LibraryApi {
  static final _cache = AsyncCache<String, List<Map<String, dynamic>>>(
    ttl: const Duration(minutes: 1),
  );
  static String? _scope;
  static bool _listening = false;
  static int _revision = 0;
  static int get revision => _revision;

  static Future<List<Map<String, dynamic>>> fetch({bool force = false}) {
    if (!_listening) {
      _listening = true;
      BackendApi.authState.addListener(() => _syncScope());
    }
    final key = _syncScope();
    final profileId = BackendApi.authState.selectedProfile?.id;
    if (profileId == null || key == null) return Future.value([]);
    return _cache.get(key, () => _fetch(profileId), force: force);
  }

  static String? _syncScope() {
    final key = BackendApi.profileCacheKey;
    if (key != _scope) {
      _scope = key;
      _cache.clear();
      _revision++;
    }
    return key;
  }

  static Future<List<Map<String, dynamic>>> _fetch(String profileId) async {
    final response = await BackendApi.dio.get(
      '${Api.ServerUrl}/track/library/$profileId',
    );
    final result = response.data['result'] as List? ?? const [];
    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> upsert({
    required int tmdbId,
    required MediaType mediaType,
    bool? watchlisted,
    String? rating,
    bool merge = false,
  }) async {
    final profileId = BackendApi.authState.selectedProfile?.id;
    final key = BackendApi.profileCacheKey;
    if (profileId == null || key == null) return;
    final type = mediaType == MediaType.movie ? 'movie' : 'show';
    final data = <String, dynamic>{'merge': merge};
    if (watchlisted != null) data['watchlisted'] = watchlisted;
    if (rating != null) data['rating'] = rating;
    await BackendApi.dio.put(
      '${Api.ServerUrl}/track/library/$profileId/$type/$tmdbId',
      data: data,
    );
    _cache.invalidate(key);
    if (key == _scope) _revision++;
  }
}
