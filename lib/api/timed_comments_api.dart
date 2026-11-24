import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/models/social/timed_comment.dart';

class TimedCommentsApi {
  final int mediaId;
  final int? season;
  final int? episode;

  const TimedCommentsApi(this.mediaId, {this.season, this.episode});

  String get _url =>
      '${Api.ServerUrl}/social/timed-comments/${episode == null ? 'movie' : 'show'}/$mediaId';

  Map<String, dynamic> get _scope => {
    'season': season ?? 0,
    'episode': episode ?? 0,
  };

  Future<List<TimedComment>> list({bool Function()? cancelled}) async {
    final comments = <TimedComment>[];
    Map<String, dynamic> cursor = {};
    do {
      if (cancelled?.call() ?? false) return const [];
      final response = await BackendApi.dio.get(
        _url,
        queryParameters: {..._scope, ...cursor},
      );
      final data = response.data as Map;
      final rows = data['result'] as List? ?? const [];
      comments.addAll(rows.map((row) =>
          TimedComment.fromJson(Map<String, dynamic>.from(row as Map))));
      final next = data['next'];
      if (next is! Map) break;
      final nextCursor = Map<String, dynamic>.from(next);
      if (nextCursor['after_ms'] == cursor['after_ms'] &&
          nextCursor['after_id'] == cursor['after_id']) break;
      cursor = nextCursor;
    } while (true);
    return comments;
  }

  Future<TimedComment> post(Duration position, String body) async {
    final profile = BackendApi.authState.selectedProfile;
    if (profile == null) throw StateError('Select a profile first.');
    final response = await BackendApi.dio.post(
      _url,
      data: {
        ..._scope,
        'profile_id': profile.id,
        'position_ms': position.inMilliseconds,
        'body': body.trim(),
      },
    );
    return TimedComment.fromJson(
      Map<String, dynamic>.from(response.data['result'] as Map),
    );
  }
}
