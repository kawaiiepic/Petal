import 'dart:async';

import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/episode.dart';
import 'package:blssmpetal/models/stream.dart';
import 'package:blssmpetal/api/api.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

import 'package:url_launcher/url_launcher.dart';

class StreamPlayer extends StatefulWidget {
  final StreamItem stream;
  final CatalogItem catalogItem;
  final Episode? episode;
  const StreamPlayer({super.key, required this.stream, required this.catalogItem, this.episode});

  @override
  State<StatefulWidget> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  bool showLeftSeek = false;
  bool showRightSeek = false;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  Future<void> _startStream() async {
    try {
      final uri = Uri.parse("${Api.ServerUrl}/transcode?url=${Uri.encodeComponent(widget.stream.url)}");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streamUrl = Api.ServerUrl + data["streamUrl"];

        print("Using HLS stream: $streamUrl");

        player.open(Media(streamUrl, httpHeaders: {"User-Agent": "PetalPlayer"}));

        if (!await launchUrl(Uri.parse(streamUrl))) {
          throw Exception('Could not launch');
        }
      } else {
        throw Exception("Transcode request failed");
      }
    } catch (e) {
      print("Transcode error: $e");

      // fallback to direct stream
      player.open(Media(widget.stream.url));
    }
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
    tooltip: 'Set Subtitles',
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

  void seekRelative(Duration offset) async {
    final current = player.state.position;
    var target = current + offset;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    await player.seek(target);
  }

  MaterialDesktopVideoControlsThemeData controls() {
    return MaterialDesktopVideoControlsThemeData(
      controlsTransitionDuration: Duration(seconds: 1),
      visibleOnMount: true,
      playAndPauseOnTap: false,
      // Modify theme options:
      seekBarThumbColor: Colors.pink.shade200,
      seekBarPositionColor: Colors.pink.shade200,
      controlsHoverDuration: const Duration(seconds: 5),
      toggleFullscreenOnDoublePress: false,
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
            children: widget.catalogItem.type == "series"
                ? [
                    Text('${widget.catalogItem.name} - S${widget.stream.season}:E${widget.stream.episode}'),
                    Text(
                      '${widget.episode?.title} (${widget.catalogItem.year})', // (${super.widget.torrentEpisode.show.year})
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ]
                : [Text(widget.catalogItem.name), Text(widget.catalogItem.year.toString())],
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
    final ValueNotifier<int> pressCount = ValueNotifier<int>(0);
    final ValueNotifier<Timer> _timer = ValueNotifier<Timer>(Timer(Duration.zero, () {}));

    return MaterialDesktopVideoControlsTheme(
      normal: controls(),
      fullscreen: controls(),
      child: Scaffold(
        body: Center(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTapUp: (details) async {
                  await player.playOrPause();
                },

                onDoubleTapDown: (details) async {
                  final width = MediaQuery.of(context).size.width;

                  if (details.globalPosition.dx < width / 2) {
                    seekRelative(const Duration(seconds: -10));

                    setState(() => showLeftSeek = true);
                    Future.delayed(const Duration(milliseconds: 600), () {
                      setState(() => showLeftSeek = false);
                    });
                  } else {
                    seekRelative(const Duration(seconds: 10));

                    setState(() => showRightSeek = true);
                    Future.delayed(const Duration(milliseconds: 600), () {
                      setState(() => showRightSeek = false);
                    });
                  }
                },

                child: Stack(
                  children: [
                    Video(controller: controller, controls: MaterialDesktopVideoControls),
                    if (showLeftSeek) _seekOverlay(left: true),
                    if (showRightSeek) _seekOverlay(left: false),
                  ],
                ),
              ),

              // Video(controller: controller, controls: MaterialDesktopVideoControls),
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

Widget _seekOverlay({required bool left}) {
  return Positioned.fill(
    child: Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(40)),
            child: Text(left ? "<< 10s" : "10s >>", style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),
        ),
      ),
    ),
  );
}
