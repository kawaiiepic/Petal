import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/models/social/activity_item.dart';
import 'package:petal/models/social/social_profile.dart';
import 'package:petal/models/social/title_comment.dart';

class SocialApi {
  static Future<List<SocialProfile>> searchProfiles(String query) async {
    final response = await BackendApi.dio.get(
      '${Api.ServerUrl}/social/profiles',
      queryParameters: {'q': query},
    );
    final rows = response.data['result'] as List? ?? const [];
    return rows
        .map((e) => SocialProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<SocialProfile?> profile(String id) async {
    final response = await BackendApi.dio.get(
      '${Api.ServerUrl}/social/profiles/$id',
    );
    final row = response.data['result'];
    if (row is! Map) return null;
    return SocialProfile.fromJson(Map<String, dynamic>.from(row));
  }

  static Future<void> follow(String profileId) async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return;
    await BackendApi.dio.put(
      '${Api.ServerUrl}/social/follows/$profileId',
      data: {'follower_id': me},
    );
  }

  static Future<void> unfollow(String profileId) async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return;
    await BackendApi.dio.delete(
      '${Api.ServerUrl}/social/follows/$profileId',
      queryParameters: {'follower_id': me},
    );
  }

  static Future<List<TitleComment>> comments(
    String mediaType,
    int tmdbId,
  ) async {
    final response = await BackendApi.dio.get(
      '${Api.ServerUrl}/social/comments/$mediaType/$tmdbId',
    );
    final rows = response.data['result'] as List? ?? const [];
    return rows
        .map((e) => TitleComment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> postComment(
    String mediaType,
    int tmdbId,
    String body,
  ) async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return;
    await BackendApi.dio.post(
      '${Api.ServerUrl}/social/comments/$mediaType/$tmdbId',
      data: {'profile_id': me, 'body': body},
    );
  }

  static Future<List<ActivityItem>> activity() async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return [];
    final response = await BackendApi.dio.get(
      '${Api.ServerUrl}/social/activity',
      queryParameters: {'follower_id': me},
    );
    final rows = response.data['result'] as List? ?? const [];
    return rows
        .map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
