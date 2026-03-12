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
  late final ValueNotifier<String?> _breadcrumb = ValueNotifier(null);
  ValueNotifier<AudioTrack?> currentAudioTrack = ValueNotifier(null);
  ValueNotifier<SubtitleTrack?> currentSubtitleTrack = ValueNotifier(null);

  bool controlsVisible = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startStream();

    currentAudioTrack.value = player.state.tracks.audio[0];
    currentSubtitleTrack.value = player.state.tracks.subtitle[0];

    player.stream.track.listen((track) {
      if (track.audio != currentAudioTrack.value) {
        currentAudioTrack.value = track.audio;
      }

      if (track.subtitle != currentSubtitleTrack.value) {
        currentSubtitleTrack.value = track.subtitle;
      }
    });
  }

  Future<void> _startStream() async {
    try {
      final uri = Uri.parse("${Api.ServerUrl}/transcode?url=${Uri.encodeComponent(widget.stream.url)}");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streamUrl = Api.ServerUrl + data["streamUrl"];

        print("Using HLS stream: $streamUrl");

        await Future.delayed(Duration(seconds: 5));

        player.open(Media(streamUrl, httpHeaders: {"User-Agent": "PetalPlayer"}));
      } else {
        throw Exception("Transcode request failed");
      }
    } catch (e) {
      print("Transcode error: $e");

      // fallback to direct stream
      player.open(Media(widget.stream.url));
    }
  }

  void showBreadcrumb(String message, {Duration duration = const Duration(seconds: 2)}) {
    _breadcrumb.value = message;
    Future.delayed(duration, () {
      _breadcrumb.value = null;
    });
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
    onSelected: (value) {
      print(value.title);
      player.setAudioTrack(value);
    },
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

        // _audioTrack(),
        MaterialDesktopCustomButton(
          onPressed: () {
            var tracks = player.state.tracks.audio.where((a) => a.language != null).toList();
            var index = tracks.indexOf(player.state.track.audio) + 1;

            if (index + 1 > tracks.length) {
              index = 0;
            }

            player.setAudioTrack(tracks[index]);
            setState(() {});
            showBreadcrumb("Audio: ${tracks[index].language}");
          },
          icon: ValueListenableBuilder<AudioTrack?>(
            valueListenable: currentAudioTrack,
            builder: (context, track, child) {
              return Tooltip(
                message: player.state.tracks.audio.where((a) => a.language != null).isEmpty
                    ? 'No audio tracks'
                    : player.state.tracks.audio
                          .where((a) => a.language != null)
                          .map((a) {
                            if (a.language == player.state.track.audio.language) {
                              return "${a.language} ";
                            } else {
                              return "${a.language}";
                            }
                          })
                          .join('\n'),
                child: Icon(Icons.audiotrack_rounded),
              );
            },
          ),
        ),
        // _subtitles(),
        MaterialDesktopCustomButton(
          onPressed: () {
            var subtitles = player.state.tracks.subtitle.where((a) => a.language != null).toList();
            var index = subtitles.indexOf(player.state.track.subtitle) + 1;

            if (index + 1 > subtitles.length) {
              index = 0;
            }

            player.setSubtitleTrack(subtitles[index]);
            setState(() {});
            showBreadcrumb("Subtitle: ${subtitles[index].title}");
          },
          icon: Tooltip(
            key: ValueKey(player.state.track.subtitle),
            message: player.state.tracks.subtitle.isEmpty
                ? 'No Subtitle tracks'
                : player.state.tracks.subtitle
                      .where((a) => a.language != null)
                      .map((a) {
                        if (a.language == player.state.track.subtitle.language) {
                          return "${a.title} ";
                        } else {
                          return "${a.title}";
                        }
                      })
                      .join('\n'),
            child: Icon(Icons.closed_caption_rounded),
          ),
        ),
        _playbackSpeed(),
        MaterialDesktopCustomButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        const MaterialDesktopFullscreenButton(),
      ],
    );
  }

double controlsOffset(BuildContext context) {
    final theme = MaterialDesktopVideoControlsTheme.maybeOf(context)?.normal;

    final buttonBarHeight = theme?.buttonBarHeight ?? 56;
    final margin = theme?.bottomButtonBarMargin.vertical ?? 0;
    final padding = theme?.padding?.bottom ?? 0;

    return buttonBarHeight + margin + padding;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialDesktopVideoControlsTheme(
      normal: controls(),
      fullscreen: controls(),
      child: Scaffold(
        body: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTapUp: (details) async {
                // await player.playOrPause();
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
                  MouseRegion(
                    onHover: (_) {
                      setState(() => controlsVisible = true);

                      timer?.cancel();
                      timer = Timer(Duration(milliseconds: 5500), () {
                        setState(() => controlsVisible = false);
                      });
                    },
                    child: Video(controller: controller),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 40,
                    child: AnimatedSlide(
                      duration: Duration(milliseconds: 200),
                      offset: controlsVisible ? Offset(0, -0.35) : Offset.zero,
                      child: Visibility(
                        visible: true,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 12, 12),
                          width: 400,
                          height: 200,
                          color: Colors.blue,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Up Next"),
                              Text("Episode 5"),
                              ElevatedButton(
                                onPressed: () {
                                  // playNextEpisode();
                                },
                                child: Text("Watch Now"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Container(
                  //   alignment: AlignmentDirectional.bottomEnd,
                  //   child: Visibility(
                  //     visible: false,
                  //     child: Container(
                  //       margin: EdgeInsets.fromLTRB(0, 0, 12, 12),
                  //       width: 400,
                  //       height: 200,
                  //       color: Colors.blue,
                  //       child: Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Text("Up Next"),
                  //           Text("Episode 5"),
                  //           ElevatedButton(
                  //             onPressed: () {
                  //               // playNextEpisode();
                  //             },
                  //             child: Text("Watch Now"),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  if (showLeftSeek) _seekOverlay(left: true),
                  if (showRightSeek) _seekOverlay(left: false),

                  // Breadcrumb overlay
                  ValueListenableBuilder<String?>(
                    valueListenable: _breadcrumb,
                    builder: (context, msg, _) {
                      if (msg == null) return const SizedBox.shrink();
                      return Center(
                        heightFactor: 20,
                        child: AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      );
                    },
                  ),
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
