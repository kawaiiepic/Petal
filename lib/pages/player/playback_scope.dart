import 'package:petal/models/episode.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Controls request an episode change from their existing player, without routing.
class PlaybackScope extends InheritedWidget {
  final Future<void> Function(Episode episode) playEpisode;
  const PlaybackScope({
    super.key,
    required this.playEpisode,
    required super.child,
  });
  static PlaybackScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlaybackScope>();
  @override
  bool updateShouldNotify(PlaybackScope oldWidget) =>
      oldWidget.playEpisode != playEpisode;
}
