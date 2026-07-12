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
  late final controller = VideoController(player);
  late final StreamItem selectedStream;
  bool zoomVideo = false;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  Future<void> _startStream() async {
    print("Starting stream");
    print(widget.movieId.toString());
    final mediaImdb = widget.showId != null ? (await TMDB.tvShow(widget.showId!)).imdbId : (await TMDB.movie(widget.movieId!)).imdbId;

    final streams = await StreamApi.fetchStreams(mediaImdb!, widget.episode);

    StreamItem? stream;

    if (widget.stream != null) {
      stream = widget.stream;
    } else {
      stream = StreamApi.autoSelectStream(streams);
    }

    if (stream != null) {
      selectedStream = stream;
      print("Best Stream found: ${selectedStream.url}");
      await player.open(Media(selectedStream.url));
    } else {
      context.pop();
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      child: Video(
        controller: controller,
        pip: const PipConfig(autoEnter: true, preferredSize: Size(1920 / 5, 1080 / 5)),
        onPipEvent: (event) {
          // Optional: observe lifecycle + play/pause events.
        },
        fit: BoxFit.cover,
        subtitleViewConfiguration: SubtitleViewConfiguration(
          style: const TextStyle(
            height: 1.4,
            fontSize: 30.0,
            letterSpacing: 0.0,
            wordSpacing: 0.0,
            color: Color(0xffffffff),
            fontWeight: FontWeight.w500,
            backgroundColor: Color.fromARGB(20, 0, 0, 0),
          ),
          textAlign: TextAlign.center,
          textScaler: TextScaler.linear(1),
          padding: const EdgeInsets.all(24.0),
        ),
        controls: (state) => customVideoControls(state, this),
      ),
    );
  }
}
