import 'package:petal/api/api.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/trakt/enum/media_type.dart';

class LibraryApi {
  static Future<List<Map<String, dynamic>>> fetch() async {
    final profileId = BackendApi.authState.selectedProfile?.id;
    if (profileId == null) return [];
    final response = await BackendApi.dio.get('${Api.ServerUrl}/track/library/$profileId');
    final result = response.data['result'] as List? ?? const [];
    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> upsert({
    required int tmdbId,
    required MediaType mediaType,
    bool? watchlisted,
    String? rating,
  }) async {
    final profileId = BackendApi.authState.selectedProfile?.id;
    if (profileId == null) return;
    final type = mediaType == MediaType.movie ? 'movie' : 'show';
    final data = <String, dynamic>{};
    if (watchlisted != null) data['watchlisted'] = watchlisted;
    if (rating != null) data['rating'] = rating;
    await BackendApi.dio.put('${Api.ServerUrl}/track/library/$profileId/$type/$tmdbId', data: data);
  }
}
