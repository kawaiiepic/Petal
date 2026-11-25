import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:petal/utils/media_formatting.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PositionDisplay extends StatefulWidget {
  final Player player;
  final bool visible;
  const PositionDisplay({
    super.key,
    required this.player,
    required this.visible,
  });

  @override
  State<PositionDisplay> createState() => _PositionDisplayState();
}

class _PositionDisplayState extends State<PositionDisplay> {
  late Duration _position = widget.player.state.position;
  StreamSubscription<Duration>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.stream.position
        .throttleTime(const Duration(seconds: 1))
        .listen(_onPosition);
  }

  void _onPosition(Duration position) {
    _position = position;
    if (widget.visible && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant PositionDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(MediaFormatting.fmt(_position),
          style: const TextStyle(fontSize: 12, color: Colors.white)),
        Text(MediaFormatting.fmt(widget.player.state.duration),
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .75))),
      ],
    ),
  );
}
