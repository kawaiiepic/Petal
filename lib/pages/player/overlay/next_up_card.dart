import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class NextUpCard extends StatefulWidget {
  final Player player;
  final Future<TmdbEpisode?> nextEpisode;
  final Function playNextEpisode;
  final bool uiIsActive;

  const NextUpCard({
    super.key,
    required this.player,
    required this.nextEpisode,
    required this.uiIsActive,
    required this.playNextEpisode,
  });

  @override
  State<StatefulWidget> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<NextUpCard> {
  Timer? _timer;
  final int _maxtime = 45;
  int _secondsLeft = 0;

  bool _started = false;

  void _startCountdown() {
    if (_started) return;

    _started = true;
    _secondsLeft = _maxtime;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsLeft == 1) {
        timer.cancel();
        widget.playNextEpisode();
      }

      setState(() {
        _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position.throttleTime(const Duration(seconds: 1)),
      builder: (context, posSnapshot) {
        final pos = posSnapshot.data ?? Duration.zero;
        final dur = widget.player.state.duration;
        final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
        final nearEnd = progress > 0.93;
        bool dismissed = false;
        final showCard = nearEnd && !dismissed;

        if (showCard) {
          _startCountdown();
        }

        if (!showCard && _started) {
          _timer?.cancel();
          _started = true;
          _secondsLeft = _maxtime;
        }

        return FutureBuilder(
          future: widget.nextEpisode,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }

            final episode = snapshot.data!;

            return IgnorePointer(
              ignoring: false,
              child: AnimatedSlide(
                offset: showCard ? const Offset(0, -0.10) : Offset.zero,
                duration: const Duration(milliseconds: 500),
                child: AnimatedOpacity(
                  opacity: showCard ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 200),
                    offset: widget.uiIsActive ? const Offset(0, -0.20) : Offset.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 20.w,
                        height: 12.h,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w300${episode.stillPath}',
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Center(child: Text('Image missing')),
                              ),
                            ),
                            Container(color: Colors.black.withAlpha(120)),
                            Center(
                              child: GestureDetector(
                                onTap: () => widget.playNextEpisode(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(40),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(LucideIcons.play, color: Colors.white, size: 26),
                                ),
                              ),
                            ),
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
                                  spacing: 8,
                                  children: [
                                    const Text(
                                      "Up Next",
                                      style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      episode.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "S${episode.seasonNumber}:E${episode.episodeNumber} · ${episode.name}",
                                      style: const TextStyle(fontSize: 11, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: LinearProgressIndicator(
                                        value: (_maxtime - _secondsLeft) / _maxtime,
                                        minHeight: 3,
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.pink,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Button(
                                style: ButtonVariance.primary,
                                onPressed: () {
                                  _timer?.cancel();
                                  setState(() {
                                    _started = false;
                                    _secondsLeft = _maxtime;
                                  });
                                },
                                child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
