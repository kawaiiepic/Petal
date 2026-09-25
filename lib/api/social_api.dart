import 'package:petal/api/api.dart';
import 'package:petal/api/trakt/backend_api.dart';

class SocialProfile {
  final String id;
  final String name;
  final String? avatar;
  final bool following;

  const SocialProfile({required this.id, required this.name, this.avatar, this.following = false});

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as String?;
    return SocialProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatar: avatar != null && !avatar.contains('builtin') ? avatar : null,
      following: json['following'] == true,
    );
  }
}

class TitleComment {
  final String id;
  final String profileId;
  final String name;
  final String? avatar;
  final String body;
  final DateTime createdAt;

  const TitleComment({required this.id, required this.profileId, required this.name, required this.body, required this.createdAt, this.avatar});

  factory TitleComment.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as String?;
    return TitleComment(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatar: avatar != null && !avatar.contains('builtin') ? avatar : null,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(((json['created_at'] as num?)?.toInt() ?? 0) * 1000),
    );
  }
}

class ActivityItem {
  final String profileId;
  final String name;
  final String? avatar;
  final int tmdbId;
  final String mediaType;
  final DateTime at;

  const ActivityItem({required this.profileId, required this.name, required this.tmdbId, required this.mediaType, required this.at, this.avatar});

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as String?;
    return ActivityItem(
      profileId: json['profile_id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatar: avatar != null && !avatar.contains('builtin') ? avatar : null,
      tmdbId: (json['tmdb_id'] as num).toInt(),
      mediaType: json['media_type'] as String? ?? 'show',
      at: DateTime.fromMillisecondsSinceEpoch(((json['updated_at'] as num?)?.toInt() ?? 0) * 1000),
    );
  }
}

class SocialApi {
  static Future<List<SocialProfile>> searchProfiles(String query) async {
    final response = await BackendApi.dio.get('${Api.ServerUrl}/social/profiles', queryParameters: {'q': query});
    final rows = response.data['result'] as List? ?? const [];
    return rows.map((e) => SocialProfile.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<SocialProfile?> profile(String id) async {
    final response = await BackendApi.dio.get('${Api.ServerUrl}/social/profiles/$id');
    final row = response.data['result'];
    if (row is! Map) return null;
    return SocialProfile.fromJson(Map<String, dynamic>.from(row));
  }

  static Future<void> follow(String profileId) async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return;
    await BackendApi.dio.put('${Api.ServerUrl}/social/follows/$profileId', data: {'follower_id': me});
  }

  static Future<void> unfollow(String profileId) async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return;
    await BackendApi.dio.delete('${Api.ServerUrl}/social/follows/$profileId', queryParameters: {'follower_id': me});
  }

  static Future<List<TitleComment>> comments(String mediaType, int tmdbId) async {
    final response = await BackendApi.dio.get('${Api.ServerUrl}/social/comments/$mediaType/$tmdbId');
    final rows = response.data['result'] as List? ?? const [];
    return rows.map((e) => TitleComment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> postComment(String mediaType, int tmdbId, String body) async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return;
    await BackendApi.dio.post('${Api.ServerUrl}/social/comments/$mediaType/$tmdbId', data: {'profile_id': me, 'body': body});
  }

  static Future<List<ActivityItem>> activity() async {
    final me = BackendApi.authState.selectedProfile?.id;
    if (me == null) return [];
    final response = await BackendApi.dio.get('${Api.ServerUrl}/social/activity', queryParameters: {'follower_id': me});
    final rows = response.data['result'] as List? ?? const [];
    return rows.map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
