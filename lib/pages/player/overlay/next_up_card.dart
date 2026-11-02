import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class NextUpCard extends StatefulWidget {
  final Player player;
  final Future<TmdbEpisode?> nextEpisode;
  final VoidCallback playNextEpisode;
  final bool suppressed;

  const NextUpCard({
    super.key,
    required this.player,
    required this.nextEpisode,
    required this.playNextEpisode,
    this.suppressed = false,
  });

  @override
  State<NextUpCard> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<NextUpCard> {
  static const _countdownSeconds = 45;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _timer;
  TmdbEpisode? _episode;
  int _secondsLeft = _countdownSeconds;
  int _generation = 0;
  bool _dismissed = false;
  bool _played = false;

  bool get _nearEnd {
    final state = widget.player.state;
    return state.duration > Duration.zero &&
        state.position.inMicroseconds / state.duration.inMicroseconds > .93;
  }

  bool get _visible =>
      _nearEnd &&
      _episode != null &&
      !_dismissed &&
      !_played &&
      !widget.suppressed;

  @override
  void initState() {
    super.initState();
    _attachPlayer();
    _loadEpisode();
  }

  void _attachPlayer() {
    void changed(Object? _) {
      if (!mounted) return;
      _syncCountdown();
      setState(() {});
    }

    _subscriptions.addAll([
      widget.player.stream.position.listen(changed),
      widget.player.stream.duration.listen(changed),
      widget.player.stream.playing.listen(changed),
      widget.player.stream.completed.listen(changed),
      widget.player.stream.buffering.listen(changed),
    ]);
  }

  Future<void> _loadEpisode() async {
    final generation = ++_generation;
    TmdbEpisode? episode;
    try {
      episode = await widget.nextEpisode;
    } catch (_) {
      /* No autoplay without a valid next episode. */
    }
    if (!mounted || generation != _generation) return;
    setState(() => _episode = episode);
    _syncCountdown();
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
  }

  void _syncCountdown() {
    if (!_nearEnd) _secondsLeft = _countdownSeconds;
    final state = widget.player.state;
    if (!_visible || (!state.playing && !state.completed) || state.buffering) {
      _stopCountdown();
      return;
    }
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_visible ||
          (!widget.player.state.playing && !widget.player.state.completed) ||
          widget.player.state.buffering) {
        _syncCountdown();
        return;
      }
      if (_secondsLeft <= 1) {
        _play();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _dismiss() {
    _stopCountdown();
    setState(() => _dismissed = true);
  }

  void _play() {
    if (!_visible) return;
    _stopCountdown();
    setState(() => _played = true);
    widget.playNextEpisode();
  }

  @override
  void didUpdateWidget(covariant NextUpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedPlayer = oldWidget.player != widget.player;
    if (changedPlayer) {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
      _attachPlayer();
    }
    if (changedPlayer || oldWidget.nextEpisode != widget.nextEpisode) {
      _stopCountdown();
      _episode = null;
      _dismissed = _played = false;
      _secondsLeft = _countdownSeconds;
      _loadEpisode();
    }
    _syncCountdown();
  }

  @override
  void dispose() {
    _generation++;
    _stopCountdown();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final episode = _episode!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _play,
            onDoubleTap: () {},
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaArtwork(imageUrl: episode.stillUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xC0101018),
                        Color(0x60101018),
                        Color(0xF0101018),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 10,
                  right: 4,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.play,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Up next',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Tooltip(
                        tooltip: (_) => const Text('Cancel autoplay'),
                        child: Semantics(
                          label: 'Cancel autoplay',
                          button: true,
                          child: IconButton(
                            variance: ButtonVariance.ghost,
                            onPressed: _dismiss,
                            icon: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        'S${episode.seasonNumber} · E${episode.episodeNumber}  ${episode.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Play next in $_secondsLeft s',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      LinearProgressIndicator(
                        value:
                            (_countdownSeconds - _secondsLeft) /
                            _countdownSeconds,
                        minHeight: 3,
                        color: Colors.pink,
                        backgroundColor: Colors.white.withValues(alpha: .25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
