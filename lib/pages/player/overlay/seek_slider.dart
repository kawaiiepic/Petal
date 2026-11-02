import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/utils/media_formatting.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SeekSlider extends StatefulWidget {
  final Player player;
  final bool visible;
  const SeekSlider({super.key, required this.player, required this.visible});

  @override
  State<SeekSlider> createState() => _SeekSliderState();
}

class _SeekSliderState extends State<SeekSlider>
    with SingleTickerProviderStateMixin {
  double? _dragValue;
  bool _isDragging = false;
  bool _seeking = false;
  bool _seekFailed = false;
  int _seekGeneration = 0;
  Duration _syncedPosition = Duration.zero;
  Duration _interpolatedPosition = Duration.zero;
  Duration _buffer = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _buffering = false;
  double _rate = 1;
  final Stopwatch _stopwatch = Stopwatch();
  late final Ticker _ticker;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _attachPlayer();
  }

  void _attachPlayer() {
    final state = widget.player.state;
    _duration = state.duration;
    _buffer = state.buffer;
    _playing = state.playing;
    _buffering = state.buffering;
    _rate = state.rate;
    _resync(state.position);
    _subscriptions.addAll([
      widget.player.stream.position.listen((position) {
        // Keep the drag/seek preview until its command finishes. Native updates
        // are not throttled, so an old position cannot mask the seek result.
        if (!_isDragging && !_seeking) _resync(position);
        _redraw();
      }),
      widget.player.stream.buffer.listen((buffer) {
        _buffer = buffer;
        _redraw();
      }),
      widget.player.stream.duration.listen((duration) {
        _duration = duration;
        _redraw();
      }),
      widget.player.stream.playing.listen((playing) {
        _playing = playing;
        if (!_isDragging && !_seeking) _resync(widget.player.state.position);
        _updateTicker();
        _redraw();
      }),
      widget.player.stream.buffering.listen((buffering) {
        _buffering = buffering;
        if (!_isDragging && !_seeking) _resync(widget.player.state.position);
        _updateTicker();
        _redraw();
      }),
      widget.player.stream.rate.listen((rate) {
        _rate = rate;
        if (!_isDragging && !_seeking) _resync(widget.player.state.position);
        _redraw();
      }),
    ]);
    _updateTicker();
  }

  void _redraw() {
    if (mounted && widget.visible) setState(() {});
  }

  void _updateTicker() {
    final advance =
        widget.visible && _playing && !_buffering && !_isDragging && !_seeking;
    if (advance && !_ticker.isActive) _ticker.start();
    if (!advance && _ticker.isActive) _ticker.stop();
  }

  void _resync(Duration position) {
    _syncedPosition = position;
    _interpolatedPosition = position;
    _stopwatch
      ..reset()
      ..start();
  }

  void _onTick(Duration elapsed) {
    var next = _syncedPosition + _stopwatch.elapsed * _rate;
    if (_duration > Duration.zero && next > _duration) next = _duration;
    _interpolatedPosition = next;
    _redraw();
  }

  void _cancelDrag() {
    if (!_isDragging) return;
    setState(() {
      _isDragging = false;
      _dragValue = null;
      _resync(widget.player.state.position);
    });
    _updateTicker();
  }

  Future<void> _finishDrag(double value) async {
    if (!_isDragging || _duration <= Duration.zero || !value.isFinite) {
      _cancelDrag();
      return;
    }
    final player = widget.player;
    final generation = ++_seekGeneration;
    final target = Duration(
      microseconds: (_duration.inMicroseconds * value.clamp(0.0, 1.0)).round(),
    );
    setState(() {
      _isDragging = false;
      _dragValue = null;
      _seeking = true;
      _seekFailed = false;
      _resync(target);
    });
    _updateTicker();
    var failed = false;
    try {
      await player.seek(target);
    } catch (_) {
      failed = true;
    }
    if (!mounted || generation != _seekGeneration) return;
    setState(() {
      _seeking = false;
      _seekFailed = failed;
      // Command completion is not proof that video has buffered there. Resume
      // displaying the actual native position instead of inventing playback.
      _resync(player.state.position);
    });
    _updateTicker();
  }

  @override
  void didUpdateWidget(covariant SeekSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _seekGeneration++;
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
      _isDragging = _seeking = _seekFailed = false;
      _dragValue = null;
      _attachPlayer();
    } else if (widget.visible != oldWidget.visible) {
      if (widget.visible && !_isDragging && !_seeking)
        _resync(widget.player.state.position);
      _updateTicker();
    }
  }

  @override
  void dispose() {
    _seekGeneration++;
    _ticker.dispose();
    _stopwatch.stop();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration;
    final ready = duration > Duration.zero;
    final live = ready
        ? (_interpolatedPosition.inMicroseconds / duration.inMicroseconds)
              .clamp(0.0, 1.0)
        : 0.0;
    final buffered = ready
        ? (_buffer.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerUp: (_) {
            // shadcn suppresses onChangeEnd when its controlled value already
            // equals the final drag value. Commit after gesture dispatch anyway.
            scheduleMicrotask(() {
              if (mounted && _isDragging) _finishDrag(_dragValue ?? live);
            });
          },
          onPointerCancel: (_) => _cancelDrag(),
          child: Slider(
            enabled: ready,
            value: SliderValue.single(
              _isDragging ? (_dragValue ?? live) : live,
            ),
            hintValue: SliderValue.single(buffered),
            valueIndicatorBuilder: (context, value) => SliderValueIndicator(
              value: value,
              formatter: (value) => MediaFormatting.fmt(duration * value),
            ),
            onChangeStart: (value) {
              setState(() {
                _isDragging = true;
                _dragValue = value.value;
              });
              _updateTicker();
            },
            onChanged: (value) {
              setState(() {
                _isDragging = true;
                _dragValue = value.value;
              });
              _updateTicker();
            },
            onChangeEnd: (value) => _finishDrag(value.value),
          ),
        ),
        if (_seekFailed)
          const Text(
            'Could not seek. Try again.',
            style: TextStyle(fontSize: 12),
          ),
      ],
    );
  }
}
