import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/social/timed_comment.dart';
import 'package:petal/models/social/title_comment.dart';

TimedComment at(int seconds) => TimedComment(
  comment: TitleComment(
    id: '$seconds', profileId: 'p', name: 'Viewer', body: 'Reaction',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  position: Duration(seconds: seconds),
);

void main() {
  final comments = [at(0), at(2), at(4), at(6), at(10), at(30)];
  test('only shows comments at or before playback, never future spoilers', () {
    expect(visibleTimedComments(comments, const Duration(seconds: 4))
        .map((c) => c.id), ['0', '2', '4']);
  });
  test('seeking skips old comments and rewinding restores local comments', () {
    expect(visibleTimedComments(comments, const Duration(seconds: 30))
        .map((c) => c.id), ['30']);
    expect(visibleTimedComments(comments, const Duration(seconds: 2))
        .map((c) => c.id), ['0', '2']);
  });
  test('expires old comments and limits crowded scenes', () {
    expect(visibleTimedComments(comments, const Duration(seconds: 6), limit: 2)
        .map((c) => c.id), ['4', '6']);
    expect(visibleTimedComments(comments, const Duration(seconds: 15)), isEmpty);
  });
  test('decodes the stored millisecond timestamp', () {
    final comment = TimedComment.fromJson({
      'id': 'a', 'profile_id': 'p', 'body': 'Hi', 'position_ms': 12345,
    });
    expect(comment.position.inMilliseconds, 12345);
  });
}
