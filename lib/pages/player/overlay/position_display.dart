import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:petal/api/misc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PositionDisplay extends StatefulWidget {
  final Player player;
  final bool visible;
  const PositionDisplay({super.key, required this.player, required this.visible});

  @override
  State<PositionDisplay> createState() => _PositionDisplayState();
}

class _PositionDisplayState extends State<PositionDisplay> {
  late Duration _position = widget.player.state.position;
  StreamSubscription<Duration>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.stream.position.throttleTime(const Duration(seconds: 1)).listen(_onPosition);
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
          spacing: 4,
          children: [
            Text(style: Misc.normalTextStyle, Misc.fmt(_position)),
            Text(style: Misc.normalTextStyle, '/'),
            Text(style: Misc.normalTextStyle, Misc.fmt(widget.player.state.duration)),
          ],
        ),
      );
}
