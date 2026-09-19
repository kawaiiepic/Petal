import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PlayPauseButton extends StatefulWidget {
  final Player player;
  const PlayPauseButton({super.key, required this.player});

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  late bool _playing = widget.player.state.playing;
  late bool _buffering = widget.player.state.buffering;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;

  @override
  void initState() {
    super.initState();
    _playingSub = widget.player.stream.playing.listen((playing) {
      if (mounted) setState(() => _playing = playing);
    });
    _bufferingSub = widget.player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _buffering = buffering);
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControlButton(
      onTap: () => widget.player.playOrPause(),
      icon: _buffering
          ? const CircularProgressIndicator(size: 50)
          : Icon(_playing ? LucideIcons.pause : LucideIcons.play, size: 50),
    );
  }
}
