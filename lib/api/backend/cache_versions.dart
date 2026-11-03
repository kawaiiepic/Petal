import 'package:dio/dio.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/cache/async_cache.dart';

abstract final class CacheVersions {
  static final _checks = AsyncCache<String, Map<String, dynamic>?>(
    ttl: const Duration(seconds: 5),
  );

  static void invalidate(String scope) => _checks.invalidate(scope);

  static Future<Map<String, dynamic>?> fetch(String scope, String profileId) =>
      _checks.get(scope, () async {
        try {
          final response = await BackendApi.dio.get(
            '${Api.ServerUrl}/sync/$profileId/versions');
          final data = Map<String, dynamic>.from(response.data['result'] as Map);
          if (data['generation'] is! String ||
              data['progress_version'] is! int || data['library_version'] is! int) {
            throw const FormatException('Invalid cache versions');
          }
          return data;
        } on DioException catch (error) {
          if (error.response?.statusCode == 404 ||
              error.response?.statusCode == 501) return null;
          rethrow;
        }
      });
}
