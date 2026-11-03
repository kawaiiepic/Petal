import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/cache_versions.dart';
import 'package:petal/api/cache/versioned_dataset.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class BackendDatasets {
  static VersionedDataset<T> create<T>({
    required String name, required String versionField,
    required Object? Function(T) encode, required T Function(Object?) decode,
    Duration? maxAge,
  }) => VersionedDataset<T>(
    name: name, versionField: versionField, encode: encode, decode: decode,
    maxAge: maxAge, server: () => Api.ServerUrl,
    isCurrentScope: (scope) => BackendApi.profileCacheKey == scope,
    versions: CacheVersions.fetch, invalidateVersions: CacheVersions.invalidate,
    read: (key) async => (await SharedPreferences.getInstance()).getString(key),
    write: (key, value) async {
      final saved = await (await SharedPreferences.getInstance()).setString(key, value);
      if (!saved) throw StateError('Could not save cached data');
    },
    remove: (key) async { await (await SharedPreferences.getInstance()).remove(key); },
  );
}
