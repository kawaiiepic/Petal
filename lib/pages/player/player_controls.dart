import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

Widget customVideoControls(VideoState state) {
  return PlayerControls(state: state);
}

class PlayerControls extends StatefulWidget {
  final VideoState state;
  const PlayerControls({super.key, required this.state});

  @override
  State<StatefulWidget> createState() => _PlayerControls();
}

class _PlayerControls extends State<PlayerControls> {
  bool _uiIsActive = false;
  late Player player;
  bool isPlaying = false;

  late Timer _positonTimer;
  Timer? _uiTimer = null;

  Duration position = Duration();
  Duration buffer = Duration();
  Duration duration = Duration();

  @override
  void initState() {
    super.initState();
    player = widget.state.widget.controller.player;
    duration = widget.state.widget.controller.player.state.duration;

    player.stream.playlist.listen((playlist) {
      showToast(
        context: context,
        builder: (context, overlay) => SurfaceCard(
          child: Basic(
            title: const Text('Event has been created'),
            subtitle: const Text('Sunday, July 07, 2024 at 12:00 PM'),
            trailing: PrimaryButton(
              size: ButtonSize.small,
              onPressed: () {
                // Close the toast programmatically when clicking Undo.
                overlay.close();
              },
              child: const Text('Undo'),
            ),
            trailingAlignment: Alignment.center,
          ),
        ),
      );
    });

    _positonTimer = Timer.periodic(Duration(milliseconds: 200), (_) {
      setState(() {
        position = player.state.position; // always refresh
        duration = player.state.duration;
      });
    });

    player.stream.playing.listen((playing) {
      isPlaying = playing;
    });
    // player.stream.duration.listen((boop) {
    //   setState(() {
    //     duration = boop;
    //   });
    // });
    player.stream.buffer.listen((buffer) {
      setState(() {
        this.buffer = buffer;
      });
    });
  }

  String formatDurationShort(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onHover: (event) {
      setState(() {
        _uiIsActive = true;
      });

      _uiTimer?.cancel();
      _uiTimer = Timer(Duration(milliseconds: 5500), () {
        setState(() => _uiIsActive = false);
      });
    },
    child: Stack(
      alignment: AlignmentGeometry.bottomRight,
      children: [
        // Fullscreen GestureDetector for tap anywhere
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              widget.state.widget.controller.player.playOrPause();
            },
            behavior: HitTestBehavior.opaque, // ensures empty areas detect taps
            child: Container(), // empty container to fill space
          ),
        ),

        // Controls overlay
        AnimatedOpacity(
          opacity: _uiIsActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      variance: ButtonVariance.ghost,
                      onPressed: () {},
                      icon: Row(children: [Icon(Icons.arrow_back_ios_new_rounded), Text("Return")]),
                    ),
                    Text('Title'),
                    ControlButton(icon: Icon(Icons.cast_rounded)),
                  ],
                ),
                Center(
                  child: ControlButton(onTap: () => player.playOrPause(), icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 50)),
                ),
                Column(
                  spacing: 8,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(40),
                      child: Container(
                        color: Colors.black.withAlpha(100),
                        padding: DirectionalEdgeInsetsDensity.only(start: 8, end: 8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [CircularProgressIndicator(), SizedBox(width: 12), Text('Transcoding...')]),
                      ),
                    ),
                    Slider(
                      value: SliderValue.single(position.inMilliseconds.toDouble() / duration.inMilliseconds.toDouble()),
                      hintValue: SliderValue.single(buffer.inMilliseconds.toDouble()),
                      onChanged: (value) {
                        final newPosition = Duration(milliseconds: (value.value.toDouble() * duration.inMilliseconds.toDouble()).toInt());
                        player.seek(newPosition);
                      },
                    ),
                    Row(
                      children: [
                        ControlButton(onTap: () => player.playOrPause(), icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                        ControlButton(icon: Icon(Icons.volume_up_rounded)),
                        Row(spacing: 4, children: [Text(formatDurationShort(position)), Text('/'), Text(formatDurationShort(duration))]),
                        Text('*'),
                        Row(children: [Text('S1'), Text('E1')]),
                        const Spacer(),
                        ControlButton(icon: Icon(Icons.amp_stories_rounded)),
                        ControlButton(icon: Icon(Icons.skip_next_rounded)),
                        DropdownButton(dropdownMenu: DropdownMenu(
                            children: [
                              MenuLabel(child: Row(children: [ControlButton(icon: Icon(Icons.arrow_back_ios_new_rounded)), Icon(Icons.subtitles_rounded),
                              Text('Subtitles'),
                              Spacer(),
                              ControlButton(icon: Icon(Icons.upload_rounded))
                              ],)),
                              MenuDivider(),
                               MenuLabel(child: Text('Subtitle')),
                              ...player.state.tracks.subtitle.map((e) => MenuLabel(child: Text(e.title ?? ''))),

                              MenuLabel(child: Text('Audio')),
                              ...player.state.tracks.audio.map((e) => MenuButton(onPressed: (context) => player.setAudioTrack(e), child: Text(e.id ?? ''))),
                            ],
                          ), icon: Icon(Icons.subtitles_rounded)),
                        ControlButton(icon: Icon(Icons.settings_rounded)),
                        ControlButton(icon: Icon(Icons.picture_in_picture_alt_rounded)),
                        ControlButton(icon: Icon(Icons.fullscreen_rounded)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Positioned(
          right: 20,
          bottom: 40,
          child: AnimatedSlide(
            duration: Duration(milliseconds: 200),
            offset: _uiIsActive ? Offset(0, -0.35) : Offset.zero,
            child: Visibility(visible: true, child: Container(width: 300, height: 170, color: Colors.pink)),
          ),
        ),
      ],
    ),
  );
}

class ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const ControlButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(variance: ButtonVariance.ghost, onPressed: onTap, icon: icon);
}

class DropdownButton extends StatelessWidget {
  final Widget icon;
  final DropdownMenu dropdownMenu;
  const DropdownButton({super.key, required this.icon, required this.dropdownMenu});

  @override
  Widget build(BuildContext context) => IconButton(
    variance: ButtonVariance.ghost,
    onPressed: () {
      showDropdown(
        context: context,
        builder: (context) => dropdownMenu,
      );
    },
    icon: icon,
  );
}
