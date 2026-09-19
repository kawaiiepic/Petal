import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/api/misc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SeekSlider extends StatefulWidget {
  final Player player;
  final bool visible;
  const SeekSlider({super.key, required this.player, required this.visible});

  @override
  State<SeekSlider> createState() => _SeekSliderState();
}

class _SeekSliderState extends State<SeekSlider> with SingleTickerProviderStateMixin {
  double? _dragValue;
  bool _isDragging = false;

  Duration _syncedPosition = Duration.zero;
  Duration _buffer = Duration.zero;

  final Stopwatch _stopwatch = Stopwatch();
  Duration _interpolatedPosition = Duration.zero;
  bool _playing = false;

  late final Ticker _ticker;

  StreamSubscription<Duration>? _sub;
  StreamSubscription<Duration>? _bufferSub;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();

    _syncedPosition = widget.player.state.position;
    _interpolatedPosition = _syncedPosition;
    _buffer = widget.player.state.buffer;
    _playing = widget.player.state.playing;

    _stopwatch.start();

    _sub = widget.player.stream.position.throttleTime(const Duration(seconds: 3)).listen(_onPosition);
    _bufferSub = widget.player.stream.buffer.throttleTime(const Duration(seconds: 5)).listen(_onBufferPosition);
    _playingSub = widget.player.stream.playing.listen((playing) {
      _playing = playing;
      _resync(_interpolatedPosition);
    });

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_playing || _isDragging) return;

    final delta = _stopwatch.elapsed;
    final duration = widget.player.state.duration;

    var next = _syncedPosition + delta;
    if (duration > Duration.zero && next > duration) {
      next = duration;
    }
    _interpolatedPosition = next;

    if (widget.visible && mounted) {
      setState(() {});
    }
  }

  void _resync(Duration position) {
    _syncedPosition = position;
    _stopwatch
      ..reset()
      ..start();
  }

  void _onPosition(Duration position) {
    _resync(position);
    _interpolatedPosition = position;
    if (widget.visible && mounted) {
      setState(() {});
    }
  }

  void _onBufferPosition(Duration position) {
    _buffer = position;
    if (widget.visible && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant SeekSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    _bufferSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.player.state.duration;
    final buffer = widget.player.state.buffer;
    double liveValue = 0;
    double liveValueBuffer = 0;
    if (duration.inSeconds > 0) {
      liveValue = (_interpolatedPosition.inSeconds / duration.inSeconds).clamp(0, 1);
    }
    if (buffer.inSeconds > 0) {
      liveValueBuffer = (_buffer.inSeconds / duration.inSeconds).clamp(0, 1);
    }
    final displayValue = _isDragging ? (_dragValue ?? liveValue) : liveValue;

    return Slider(
      value: SliderValue.single(displayValue),
      hintValue: SliderValue.single(liveValueBuffer),
      valueIndicatorBuilder: (context, value) {
        return SliderValueIndicator(value: value, formatter: (value) => Misc.fmt(duration * value));
      },
      onChangeStart: (v) {
        _isDragging = true;
        _dragValue = v.value;
      },
      onChanged: (v) {
        setState(() {
          _dragValue = v.value;
        });
      },
      onChangeEnd: (v) {
        final target = Duration(milliseconds: (v.value * duration.inMilliseconds).toInt());
        widget.player.seek(target);
        _resync(target);
        _interpolatedPosition = target;
        setState(() {
          _isDragging = false;
          _dragValue = null;
        });
      },
    );
  }
}
