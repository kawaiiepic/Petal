import 'dart:async';
import 'package:flutter/services.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/models/stream.dart';
import 'package:petal/pages/player/player_controls.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/pages/splash.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StreamPlayer extends StatefulWidget {
  final int? showId;
  final int? movieId;
  final Episode? episode;
  final StreamItem? stream;
  const StreamPlayer({super.key, required this.showId, required this.movieId, required this.episode, this.stream});

  @override
  State<StatefulWidget> createState() => StreamPlayerState();
}

class StreamPlayerState extends State<StreamPlayer> {
  late final player = Player();
  late final VideoController controller;
  late final StreamItem selectedStream;
  bool zoomVideo = false;
  bool _controllerReady = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _startStream();
  }

  Future<void> _startStream() async {
    try {
      final mediaImdb = widget.showId != null ? (await TMDB.tvShow(widget.showId!)).imdbId : (await TMDB.movie(widget.movieId!)).imdbId;

      final streams = await StreamApi.fetchStreams(mediaImdb!, widget.episode);
      final stream = widget.stream ?? StreamApi.autoSelectStream(streams);

      if (stream == null) {
        if (mounted) context.pop();
        return;
      }

      selectedStream = stream;

      // Fixed texture size - set once, sized to a real target resolution.
      // 1920x1080 is a sane cap; scale down if targeting lower-end devices.
      controller = VideoController(player, configuration: const VideoControllerConfiguration(width: 1920, height: 1080));

      await player.open(Media(selectedStream.url));
      if (mounted) setState(() => _controllerReady = true);
    } catch (e, st) {
      debugPrint('Failed to start stream: $e\n$st');
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerReady) {
      return SplashScreen();
    }

    return Stack(
      children: [
        Center(
          child: zoomVideo
              ? Positioned.fill(
                  child: RepaintBoundary(
                    child: Video(
                      controller: controller,
                      controls: NoVideoControls,
                      pip: const PipConfig(autoEnter: true, preferredSize: Size(1920 / 5, 1080 / 5)),
                      fit: BoxFit.cover, // crops to fill entirely, no letterboxing
                    ),
                  ),
                )
              : AspectRatio(
                  aspectRatio: 16 / 9,
                  child: RepaintBoundary(
                    child: Video(
                      controller: controller,
                      controls: NoVideoControls,
                      pip: const PipConfig(autoEnter: true, preferredSize: Size(1920 / 5, 1080 / 5)),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
        Positioned.fill(child: RepaintBoundary(child: customVideoControls(player, this))),
      ],
    );
  }
}
