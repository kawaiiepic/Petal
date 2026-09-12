import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/models/stream.dart';
import 'package:petal/pages/player/overlay/player_controls.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StreamPlayer extends StatefulWidget {
  final int mediaId;
  final Episode? episode;
  final StreamItem? stream;
  const StreamPlayer({super.key, required this.mediaId, required this.episode, this.stream});

  @override
  State<StatefulWidget> createState() => StreamPlayerState();
}

class StreamPlayerState extends State<StreamPlayer> {
  late final player = Player(configuration: PlayerConfiguration());
  late final VideoController controller;
  late final StreamItem selectedStream;
  bool zoomVideo = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    controller = VideoController(player, configuration: VideoControllerConfiguration());

    player.stream.error.listen((event) {
      showToast(context: context, builder: buildToast, location: ToastLocation.bottomLeft);
      if (mounted) context.pop();
    });

    _startStream();
  }

  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: const Text('Stream failed to load'),
        subtitle: Text(selectedStream.title),
        trailing: PrimaryButton(
          size: ButtonSize.small,
          onPressed: () {
            // Close the toast programmatically when clicking Undo.
            overlay.close();
          },
          child: const Text('Retry'),
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  Future<void> _startStream() async {
    final mediaImdb = widget.episode != null ? (await TMDB.tvShow(widget.mediaId)).imdbId : (await TMDB.movie(widget.mediaId)).imdbId;

    final streams = await StreamApi.fetchStreams(mediaImdb!, widget.episode);
    final stream = widget.stream ?? StreamApi.autoSelectStream(streams);

    if (stream == null) {
      if (mounted) context.pop();
      return;
    }

    selectedStream = stream;

    print(selectedStream.url);

    await player.open(Media(selectedStream.url, extras: {'mediaId': widget.mediaId, 'episode': widget.episode}));

    player.stream.tracks.listen((event) {
      List<VideoTrack> videos = event.video;
      List<AudioTrack> audios = event.audio;
      List<SubtitleTrack> subtitles = event.subtitle;

      final preferredLanAudio = audios.firstWhereOrNull((audio) => audio.language == "en" && audio.title == null);
      final preferredLanSub = subtitles.firstWhereOrNull((sub) => sub.language == "en" && sub.title == null);

      if (preferredLanAudio != null) {
        player.setAudioTrack(preferredLanAudio);
      } else {
        print("English track missing");
      }

      if (preferredLanSub != null) {
        player.setSubtitleTrack(preferredLanSub);
      } else {
        print("English subtitle missing");
      }
    });

    player.stream.playing.listen((bool playing) {
      if (playing) {
        // Playing.
      } else {
        // Paused.
      }
    });
  }

  Future<void> closeStream() async {
    await player.pause();

    print("Progress is: ${player.state.position.inMinutes / player.state.duration.inMinutes}");

    try {
      await BackendApi.setProgress(
        widget.mediaId,
        widget.episode != null ? "episode" : "movie",
        widget.episode?.seasonNumber ?? 0,
        widget.episode?.episodeNumber ?? 0,
        player.state.position.inSeconds / player.state.duration.inSeconds,
      );
    } catch (e) {
      print("Failed to save progress: $e");
    }

    if (mounted) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      context.pop();
    }
  }

  @override
  void dispose() {
    Discord.resetStatus();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      controls: videoControls,
      fit: BoxFit.contain,
      aspectRatio: 16 / 9,
      pip: const PipConfig(autoEnter: true, preferredSize: Size(1920 / 5, 1080 / 5)),
    );
  }
}
