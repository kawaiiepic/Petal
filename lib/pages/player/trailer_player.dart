import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/pages/player/js_solver.dart';
import 'package:petal/pages/splash.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class TrailerPlayer extends StatefulWidget {
  final String youtubeKey; // TmdbVideo.key

  const TrailerPlayer({super.key, required this.youtubeKey});

  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  late final player = Player(configuration: PlayerConfiguration());
  late final controller = VideoController(player);

  yt.YoutubeExplode _yt = yt.YoutubeExplode();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    _startTrailer();
  }

  Future<void> _startTrailer() async {
    try {
      _yt = yt.YoutubeExplode(jsSolver: FlutterJsSolver());

      final manifest = await _yt.videos.streamsClient.getManifest(widget.youtubeKey, ytClients: [yt.YoutubeApiClient.androidVr]);

      // Muxed (progressive) streams are capped around 360-720p — YouTube only
      // serves real 1080p+ as separate video-only and audio-only adaptive streams.
      final video = manifest.videoOnly.withHighestBitrate();
      // final audio = manifest.audioOnly.withHighestBitrate();

      print(video.url);

      await player.open(Media(video.url.toString()), play: true);

      // Attach the separate audio-only stream as an external track.
      // await player.setAudioTrack(AudioTrack.uri(audio.url.toString(), title: 'Audio'));

      // await player.play();
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      debugPrint('Failed to start trailer: $e\n$st');
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    player.dispose();
    _yt.close();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return SplashScreen();

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: RepaintBoundary(
              child: Video(controller: controller, controls: MaterialDesktopVideoControls, fit: BoxFit.contain),
            ),
          ),
        ),
        // Simple close button — trailers don't need your full custom controls surface,
        // but swap this for `customVideoControls(player, this)` if you'd rather match
        // the streaming player's look.
        Positioned(
          top: 16,
          left: 16,
          child: IconButton.ghost(
            onPressed: () => context.pop(),
            shape: ButtonShape.circle,
            icon: const Icon(LucideIcons.x, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
