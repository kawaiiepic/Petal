import 'package:media_kit/media_kit.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class VolumeButton extends StatefulWidget {
  final Player player;
  const VolumeButton({super.key, required this.player});

  @override
  State<VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<VolumeButton> {
  bool _hovered = false;
  double _volume = 100;

  @override
  void initState() {
    super.initState();
    _volume = widget.player.state.volume;
    widget.player.stream.volume.listen((v) {
      if (mounted) setState(() => _volume = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ControlButton(
            icon: Icon(
              size: Misc.normalIconSize,
              _volume == 0
                  ? LucideIcons.volumeX
                  : _volume < 50
                      ? LucideIcons.volume1
                      : LucideIcons.volume2,
            ),
            onTap: () => widget.player.setVolume(_volume == 0 ? 100 : 0),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: !_hovered,
              child: Row(
                children: [
                  SizedBox(
                    width: _hovered ? 100 : 0,
                    child: Opacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      child: Slider(
                        value: SliderValue.single(_volume / 100),
                        onChanged: (value) {
                          final v = value.value * 100;
                          setState(() => _volume = v);
                          widget.player.setVolume(v);
                        },
                      ),
                    ),
                  ),
                  Gap(_hovered ? 5 : 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
