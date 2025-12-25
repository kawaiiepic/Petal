import 'package:blssmpetal/models/stream.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class StreamPlayer extends StatefulWidget {
  final StreamItem stream;
  const StreamPlayer({super.key, required this.stream});

  @override
  State<StatefulWidget> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();

    // Play a [Media] or [Playlist].
    player.open(Media(widget.stream.url!));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  MaterialDesktopCustomButton _rewind() => MaterialDesktopCustomButton(
    onPressed: () {
      if ((player.state.position - const Duration(seconds: 30)).isNegative) {
        player.seek(Duration());
      } else {
        player.seek(player.state.position - const Duration(seconds: 30));
      }
    },
    icon: const Icon(Icons.fast_rewind_rounded),
  );

  MaterialDesktopCustomButton _forward() => MaterialDesktopCustomButton(
    onPressed: () {
      player.seek(player.state.position + const Duration(seconds: 30));
    },
    icon: const Icon(Icons.fast_forward_rounded),
  );

  PopupMenuButton _audioTrack() => PopupMenuButton<AudioTrack>(
    icon: const Icon(Icons.audiotrack_rounded),
    onSelected: player.setAudioTrack,
    itemBuilder: (_) {
      return player.state.tracks.audio.where((t) => t.language != null).map((t) => PopupMenuItem(value: t, child: Text(t.language!))).toList();
    },
  );

  PopupMenuButton _subtitles() => PopupMenuButton<SubtitleTrack>(
    icon: const Icon(Icons.closed_caption_rounded),
    onSelected: player.setSubtitleTrack,
    itemBuilder: (_) {
      return player.state.tracks.subtitle.where((t) => t.language != null).map((t) => PopupMenuItem(value: t, child: Text(t.language!))).toList();
    },
  );

  PopupMenuButton _playbackSpeed() => PopupMenuButton<double>(
    icon: const Icon(Icons.speed),
    onSelected: player.setRate,
    itemBuilder: (_) => const [
      PopupMenuItem(value: 0.75, child: Text('0.75x')),
      PopupMenuItem(value: 1.0, child: Text('1.0x')),
      PopupMenuItem(value: 1.25, child: Text('1.25x')),
      PopupMenuItem(value: 1.5, child: Text('1.5x')),
      PopupMenuItem(value: 2.0, child: Text('2.0x')),
    ],
  );

  MaterialDesktopVideoControlsThemeData controls() {
    return MaterialDesktopVideoControlsThemeData(
      controlsTransitionDuration: Duration(seconds: 1),
      visibleOnMount: true,
      playAndPauseOnTap: false,
      // Modify theme options:
      seekBarThumbColor: Colors.pink.shade200,
      seekBarPositionColor: Colors.pink.shade200,
      controlsHoverDuration: const Duration(seconds: 5),
      toggleFullscreenOnDoublePress: true,
      primaryButtonBar: [MaterialPlayOrPauseButton(iconSize: 48.0)],
      // Modify top button bar:
      topButtonBar: [
        MaterialDesktopCustomButton(
          onPressed: () {
            player.stop();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.keyboard_arrow_left),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$showName - S\$seasonId:E\$episodeId'),
              Text(
                '\$episodeName (\$episodeYear)', // (${super.widget.torrentEpisode.show.year})
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(widget.stream.name),
              Text(
                widget.stream.title,
                maxLines: 2,
                overflow: TextOverflow.fade,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
      // Modify bottom button bar:
      bottomButtonBar: [
        const MaterialDesktopSkipPreviousButton(),
        _rewind(),
        const MaterialDesktopPlayOrPauseButton(),
        _forward(),
        const MaterialDesktopSkipNextButton(),
        const MaterialDesktopVolumeButton(),
        const MaterialDesktopPositionIndicator(),
        const Spacer(),
        _audioTrack(),
        _subtitles(),
        _playbackSpeed(),
        MaterialDesktopCustomButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        const MaterialDesktopFullscreenButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialDesktopVideoControlsTheme(
      normal: controls(),
      fullscreen: controls(),
      child: Scaffold(
        body: Center(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Video(controller: controller, controls: MaterialDesktopVideoControls),

              // Visibility(
              //   visible: true,
              //   child: Container(
              //     margin: EdgeInsets.fromLTRB(0, 12, 12, 0),
              //     width: 100,
              //     height: 100,
              //     color: Colors.blue,
              //     child: Center(child: Text("I'm visible")),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
