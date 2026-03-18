import 'dart:async';

import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/stream.dart';
import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/models/stremio/stremio_episode.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StreamPlayer extends StatefulWidget {
  final StreamItem stream;
  final CatalogItem catalogItem;
  final StremioEpisode? episode;
  final TraktShow? traktShow;
  const StreamPlayer({super.key, required this.stream, required this.catalogItem, this.episode, this.traktShow});

  @override
  State<StatefulWidget> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  late final player = Player();
  late final controller = VideoController(player);

  late final ValueNotifier<StremioEpisode> _currentEpisode;

  bool controlsVisible = false;
  bool showNextUp = false;
  bool disableNextUp = false;
  Future<List<TraktSeason>>? _showSeasons;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    print(widget.catalogItem.id);

    _currentEpisode = ValueNotifier(widget.episode!);
    _showSeasons = TraktApi.fetchShowSeasons(widget.catalogItem.id);

    _startStream(widget.stream.url);

    player.stream.position.listen((pos) {
      if (player.state.duration.inSeconds > 0 && (player.state.duration - player.state.position).inMinutes < 2) {
        if (!showNextUp) {
          setState(() {
            showNextUp = true;
          });
        }
      } else if (showNextUp) {
        setState(() {
          showNextUp = false;
        });
      }
    });
  }

  Future<void> _startStream(String url) async {
    final trakt = (await _showSeasons)![_currentEpisode.value.season - 1].episodes[_currentEpisode.value.episode - 1].ids!.trakt;
    TraktApi.startWatching(MediaType.show, {
      "episode": {
        "ids": {"trakt": trakt},
      },
      "progress": 0,
    });

    print(url);

    if (kIsWeb) {
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
    } else {
      player.open(Media(url));
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
    _currentEpisode.dispose();
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

  MaterialDesktopVideoControlsThemeData controls() {
    return MaterialDesktopVideoControlsThemeData(
      controlsTransitionDuration: Duration(seconds: 1),
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
          child: ValueListenableBuilder<StremioEpisode>(
            valueListenable: _currentEpisode,
            builder: (context, ep, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.catalogItem.type == "series"
                  ? [
                      Text('${widget.catalogItem.name} - S${ep.season}:E${ep.episode}'),
                      Text('${ep.title} (${widget.catalogItem.year})', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    ]
                  : [Text(widget.catalogItem.name), Text(widget.catalogItem.year.toString())],
            ),
          ),
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
            child: Text(
              widget.stream.title,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ],
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
            Stack(
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
                      visible: showNextUp && !disableNextUp,
                      child: FutureBuilder(
                        future: _showSeasons,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || _showSeasons == null) {
                            return Container();
                          }
                          final season = snapshot.data![_currentEpisode.value.season - 1];
                          final episode = season.episodes[_currentEpisode.value.episode];
                          return Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                            width: 300,
                            height: 170,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Thumbnail
                                FutureBuilder(
                                  future: TMDB.still(widget.traktShow!.show.ids.tmdb.toString(), episode.season!, episode.number),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
                                    }
                                    return const SizedBox();
                                  },
                                ),

                                // Dim overlay
                                Container(color: Colors.black.withAlpha(120)),

                                // Play button in center
                                Center(
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withAlpha(40),
                                      border: Border.all(color: Colors.white60, width: 1.5),
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                                  ),
                                ),

                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => setState(() => disableNextUp = true),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withAlpha(120)),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),

                                // Info + progress at bottom
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withAlpha(230), Colors.transparent],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Up Next",
                                          style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.catalogItem.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "S${episode.season}:E${episode.number} · ${episode.title}",
                                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                        // Countdown loading bar
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 1.0, end: 0.0),
                                          duration: const Duration(seconds: 10),
                                          onEnd: () async {
                                            final addons = await Api.addonsFuture;

                                            final stremioEpisode = StremioEpisode(
                                              season: season.number,
                                              episode: episode.number,
                                              title: episode.title!,
                                              overview: '',
                                              thumbnail: '',
                                            );
                                            final streams = await StreamApi.fetchStreams(widget.catalogItem, addons!, episode: stremioEpisode);
                                            final best = StreamApi.autoSelectStream(streams);

                                            if (mounted) setState(() => _currentEpisode.value = stremioEpisode);
                                            _startStream(best!.url);
                                          }, // call playNextEpisode() here
                                          builder: (context, value, _) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(99),
                                              child: LinearProgressIndicator(
                                                value: value,
                                                minHeight: 3,
                                                backgroundColor: Colors.white24,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
