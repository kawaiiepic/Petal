import 'package:petal/models/social/title_comment.dart';

class TimedComment {
  final TitleComment comment;
  final Duration position;

  const TimedComment({required this.comment, required this.position});

  String get id => comment.id;

  factory TimedComment.fromJson(Map<String, dynamic> json) => TimedComment(
    comment: TitleComment.fromJson(json),
    position: Duration(milliseconds: (json['position_ms'] as num).toInt()),
  );
}

/// Sorted comments visible at the current playback position. Looking backward
/// only prevents spoilers after seeking or resuming playback.
List<TimedComment> visibleTimedComments(
  List<TimedComment> sorted,
  Duration position, {
  Duration lifetime = const Duration(seconds: 5),
  int limit = 3,
}) {
  if (limit <= 0) return const [];
  int lo = 0, hi = sorted.length;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    if (sorted[mid].position <= position) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  final end = lo;
  final startTime = position - lifetime;
  while (lo > 0 &&
      end - lo < limit &&
      sorted[lo - 1].position > startTime) {
    lo--;
  }
  return sorted.sublist(lo, end);
}
