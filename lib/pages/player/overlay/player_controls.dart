import 'dart:math' as math;

import 'package:petal/pages/player/overlay/player_debug_overlay.dart';

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:petal/pages/player/overlay/episode_drawer.dart';
import 'package:petal/pages/player/overlay/next_up_card.dart';
import 'package:petal/pages/player/overlay/play_pause_button.dart';
import 'package:petal/pages/player/overlay/player_settings_menu_button.dart';
import 'package:petal/pages/player/overlay/position_display.dart';
import 'package:petal/pages/player/overlay/seek_indicator.dart';
import 'package:petal/pages/player/overlay/seek_slider.dart';
import 'package:petal/pages/player/overlay/subtitle_audio_menu_button.dart';
import 'package:petal/pages/player/overlay/volume_button.dart';
import 'package:petal/pages/splash_screen.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

Widget videoControls(VideoState state) {
  return PlayerControls(state: state);
}

class PlayerControls extends StatefulWidget {
  final VideoState state;

  const PlayerControls({super.key, required this.state});

  @override
  State<StatefulWidget> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _showControls = true;
  bool _showDebug = false;
  late bool _isShow;
  late Future<(TmdbShow, TmdbEpisode)> _showData;
  late Future<TmdbMovie> _movie;
  Timer? _hideTimer;

  int _leftSeekSeconds = 0;
  int _rightSeekSeconds = 0;
  bool _showLeftSeek = false;
  bool _showRightSeek = false;
  Timer? _leftSeekTimer;
  Timer? _rightSeekTimer;
  late Future<TmdbEpisode?> _nextUpEpisode;

  Map<String, dynamic>? extras;
  late Player player;

  late int mediaId;
  late Episode episode;
  bool init = false;
  bool _offline = false;
  StreamSubscription? _playlistSub;

  void _seekBackward() {
    final newPosition =
        widget.state.widget.controller.player.state.position -
        const Duration(seconds: 10);
    player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);

    setState(() {
      _leftSeekSeconds += 10;
      _showLeftSeek = true;
    });

    _leftSeekTimer?.cancel();
    _leftSeekTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showLeftSeek = false;
          _leftSeekSeconds = 0;
        });
      }
    });
  }

  void _seekForward() {
    final duration = player.state.duration;
    final newPosition = player.state.position + const Duration(seconds: 10);
    player.seek(newPosition > duration ? duration : newPosition);

    setState(() {
      _rightSeekSeconds += 10;
      _showRightSeek = true;
    });

    _rightSeekTimer?.cancel();
    _rightSeekTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showRightSeek = false;
          _rightSeekSeconds = 0;
        });
      }
    });
  }

  void _playNextEpisode() async {
    if (_offline) return;
    final extras =
        widget.state.widget.controller.player.state.playlist.medias[0].extras;
    final mediaId = extras?["mediaId"];
    TmdbEpisode? nextEpisode = await _nextUpEpisode;
    if (nextEpisode != null) {
      context.pushReplacement(
        '/player?media=${mediaId}&s=${nextEpisode.seasonNumber}&e=${nextEpisode.episodeNumber}',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _startHideTimer();

    player = widget.state.widget.controller.player;

    final currentPlaylist = player.state.playlist;
    if (currentPlaylist.medias.isNotEmpty) {
      _onPlaylistExtras(currentPlaylist.medias[currentPlaylist.index].extras);
    }

    _playlistSub = player.stream.playlist.listen((playlist) {
      if (playlist.medias.isNotEmpty) {
        _onPlaylistExtras(playlist.medias[playlist.index].extras);
        if (mounted) setState(() {});
      }
    });
  }

  void _onPlaylistExtras(Map<String, dynamic>? newExtras) {
    extras = newExtras;
    _isShow = extras?["episode"] != null;
    mediaId = extras?["mediaId"] ?? 0;
    init = true;
    _offline = extras?['offline'] == true;
    if (_offline) {
      if (_isShow) episode = extras!['episode'];
      _nextUpEpisode = Future.value(null);
      return;
    }

    if (_isShow) {
      episode = extras!["episode"];
      _showData = (
        TMDB.tvShow(mediaId),
        TMDB.tvEpisode(mediaId, episode.seasonNumber, episode.episodeNumber),
      ).wait;
      _nextUpEpisode = nextUpEpisode();
    } else {
      _movie = TMDB.movie(mediaId);
    }
  }

  void _toggleDebug() {
    setState(() {
      _showDebug = !_showDebug;
      _showControls = true;
    });
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_showDebug) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onMouseMove({bool toggle = false}) {
    if (_showDebug) return;
    if (!_showControls) {
      setState(() => _showControls = true);
      _startHideTimer();
    } else if (toggle) {
      setState(() => _showControls = false);
      _hideTimer?.cancel();
    }
  }

  Future<TmdbEpisode?> nextUpEpisode() async {
    if (_offline) return null;
    TmdbShow show = (await _showData).$1;
    TmdbEpisode? nextEp;
    var realSeason = show.seasons.firstWhere(
      (s) => s.seasonNumber == episode.seasonNumber,
    );
    if (realSeason.episodeCount <= episode.episodeNumber) {
      if (show.seasons.length <= episode.seasonNumber) {
        return null;
      }
      nextEp = await TMDB.tvEpisode(mediaId, episode.seasonNumber + 1, 1);
    } else {
      nextEp = await TMDB.tvEpisode(
        mediaId,
        episode.seasonNumber,
        episode.episodeNumber + 1,
      );
    }

    final airDate = nextEp.airDate;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (airDate?.isBefore(todayOnly) ?? false) {
      return nextEp;
    }

    return null;
  }

  @override
  void dispose() {
    _leftSeekTimer?.cancel();
    _rightSeekTimer?.cancel();
    _hideTimer?.cancel();
    _playlistSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      return SplashScreen();
    }

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onDoubleTapDown: (details) {
        if (_showDebug) return;
        final width = context.size?.width ?? MediaQuery.of(context).size.width;
        final tapX = details.localPosition.dx;

        if (tapX < width / 2) {
          _seekBackward();
        } else {
          _seekForward();
        }
      },
      onTapDown: (details) {
        _onMouseMove(toggle: true);
      },
      child: MouseRegion(
        onHover: (event) => _onMouseMove(),
        onEnter: (_) => setState(() => _showControls = true),
        onExit: (_) {
          if (!_showDebug) setState(() => _showControls = false);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final nextBottom = _showControls ? 100.0 : 24.0;
            final nextWidth = math.min(
              320.0,
              math.min(
                math.max(0.0, constraints.maxWidth - 40),
                math.max(0.0, constraints.maxHeight - nextBottom - 12) * 16 / 9,
              ),
            );
            return Stack(
              children: [
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: TickerMode(
                    enabled: _showControls,
                    child: _buildControlsBar(),
                  ),
                ),
                if (_showDebug)
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 56, 12, 96),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: PlayerDebugOverlay(
                              player: player,
                              onClose: _toggleDebug,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SeekIndicator(
                  visible: _showLeftSeek,
                  seconds: _leftSeekSeconds,
                  isLeft: true,
                ),
                SeekIndicator(
                  visible: _showRightSeek,
                  seconds: _rightSeekSeconds,
                  isLeft: false,
                ),
                if (_isShow && !_offline)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    right: 20,
                    bottom: nextBottom,
                    width: nextWidth,
                    child: NextUpCard(
                      player: player,
                      nextEpisode: _nextUpEpisode,
                      suppressed: _showDebug || nextWidth < 160,
                      playNextEpisode: _playNextEpisode,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlsBar() {
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    variance: ButtonVariance.ghost,
                    onPressed: () => context.pop(),
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          size: AppTypography.normalIconSize,
                          LucideIcons.chevronLeft,
                        ),
                        Text(style: AppTypography.normalTextStyle, "Return"),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: _offline
                      ? Column(
                          children: [
                            Text(
                              extras?['title'] as String? ?? 'Downloaded video',
                              style: AppTypography.normalTextStyle,
                            ),
                            if (extras?['subtitle'] != null)
                              Text(
                                extras!['subtitle'] as String,
                                style: AppTypography.normalTextStyle,
                              ),
                          ],
                        )
                      : FutureBuilder(
                          future: _isShow ? _showData : _movie,
                          builder: (context, snapshot) {
                            return Column(
                              spacing: 8,
                              children: [
                                Text(
                                  style: AppTypography.normalTextStyle,
                                  snapshot.hasData
                                      ? _isShow
                                            ? (snapshot.data!
                                                      as (
                                                        TmdbShow,
                                                        TmdbEpisode,
                                                      ))
                                                  .$1
                                                  .name
                                            : (snapshot.data! as TmdbMovie)
                                                  .title
                                      : "Example Media Name",
                                ),
                                if (_isShow)
                                  Text(
                                    style: AppTypography.normalTextStyle,
                                    snapshot.hasData
                                        ? "${(snapshot.data! as (TmdbShow, TmdbEpisode)).$2.seasonNumber}x${(snapshot.data! as (TmdbShow, TmdbEpisode)).$2.episodeNumber} ${(snapshot.data! as (TmdbShow, TmdbEpisode)).$2.name}"
                                        : "Example Episode Name",
                                  ),
                              ],
                            ).asSkeleton(
                              enabled:
                                  snapshot.connectionState !=
                                  ConnectionState.done,
                            );
                          },
                        ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Tooltip(
                    tooltip: (_) => Text(
                      _showDebug
                          ? 'Hide playback diagnostics'
                          : 'Show playback diagnostics',
                    ),
                    child: Semantics(
                      label: 'Playback diagnostics',
                      toggled: _showDebug,
                      child: ControlButton(
                        onTap: _toggleDebug,
                        icon: Icon(
                          LucideIcons.info,
                          size: AppTypography.normalIconSize,
                          color: _showDebug ? Colors.pink : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(child: PlayPauseButton(player: player)),
          Column(
            spacing: 8,
            children: [
              RepaintBoundary(
                child: SeekSlider(player: player, visible: _showControls),
              ),
              Row(
                spacing: 8,
                children: [
                  ControlButton(
                    onTap: () => setState(() {
                      player.playOrPause();
                    }),
                    icon: Icon(
                      size: AppTypography.normalIconSize,
                      player.state.playing
                          ? LucideIcons.pause
                          : LucideIcons.play,
                    ),
                  ),
                  if (!Api.isMobile()) VolumeButton(player: player),
                  PositionDisplay(player: player, visible: _showControls),
                  if (_isShow) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          style: AppTypography.normalTextStyle,
                          'S${episode.seasonNumber}',
                        ),
                        Text(
                          style: AppTypography.normalTextStyle,
                          'E${episode.episodeNumber}',
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!_offline)
                      EpisodeDrawer(showData: _showData, tmdbId: mediaId),
                    if (!_offline)
                      ControlButton(
                        onTap: () async {
                          _playNextEpisode();
                        },
                        icon: Icon(
                          size: AppTypography.normalIconSize,
                          LucideIcons.skipForward,
                        ),
                      ),
                  ],
                  if (!_isShow) ...[const Spacer()],
                  SubtitleAudioMenuButton(
                    player: player,
                    onChanged: () => setState(() {}),
                  ),
                  PlayerSettingsMenuButton(player: player),
                  ControlButton(
                    onTap: () {},
                    icon: Icon(
                      size: AppTypography.normalIconSize,
                      false
                          ? RadixIcons.exitFullScreen
                          : RadixIcons.enterFullScreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
