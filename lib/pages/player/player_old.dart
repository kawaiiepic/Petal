import 'dart:async';
import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/models/custom_model.dart';
import 'package:blssmpetal/models/stream.dart';
import 'package:blssmpetal/pages/player/player_controls.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StreamPlayer extends StatefulWidget {
  final int? showId;
  final int? movieId;
  final Episode? episode;
  const StreamPlayer({super.key, required this.showId, required this.movieId, required this.episode});

  @override
  State<StatefulWidget> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  late final player = Player();
  late final controller = VideoController(player);
  late final StreamItem selectedStream;

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

    final stream = StreamApi.autoSelectStream(streams);

    if (stream != null) {
      selectedStream = stream;
      print("Best Stream found: ${selectedStream.url}");
      await player.open(Media(selectedStream.url));
    } else {
      context.pop();

      showToast(
        context: context,
        builder: (context, overlay) => SurfaceCard(
          child: Basic(title: const Text('Stream'), subtitle: const Text('No Streams available'), trailingAlignment: Alignment.center),
        ),
        location: ToastLocation.bottomRight,
      );
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Video(controller: controller, controls: (state) => customVideoControls(state, widget)),
    );
  }
}
