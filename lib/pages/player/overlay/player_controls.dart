import 'dart:async';

import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/models/custom_model.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:petal/pages/player/overlay/episode_drawer.dart';
import 'package:petal/pages/player/overlay/play_pause_button.dart';
import 'package:petal/pages/player/overlay/position_display.dart';
import 'package:petal/pages/player/overlay/seek_indicator.dart';
import 'package:petal/pages/player/overlay/seek_slider.dart';
import 'package:petal/pages/player/overlay/track_menus.dart';
import 'package:petal/pages/player/overlay/volume_button.dart';
import 'package:petal/pages/splash.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

Widget videoControls(VideoState state) {
  return PlayerControls(state: state);
}

class PlayerControls extends StatefulWidget {
  final VideoState state;

  const PlayerControls({super.key, required this.state});

  @override
  State<StatefulWidget> createState() => _PlayerControls();
}

class _PlayerControls extends State<PlayerControls> {
  bool _showControls = true;
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
  StreamSubscription<(bool, Duration)>? _discordSub;

  Map<String, dynamic>? extras;
  late Player player;

  late int mediaId;
  late Episode episode;
  bool init = false;

  void _seekBackward() {
    final newPosition = widget.state.widget.controller.player.state.position - const Duration(seconds: 10);
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
    final extras = widget.state.widget.controller.player.state.playlist.medias[0].extras;
    final mediaId = extras?["mediaId"];
    TmdbEpisode? nextEpisode = await _nextUpEpisode;
    if (nextEpisode != null) {
      context.pushReplacement('/player?media=${mediaId}&s=${nextEpisode.seasonNumber}&e=${nextEpisode.episodeNumber}');
    }
  }

  StreamSubscription? _playlistSub;

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
      }
    });
  }

  void _onPlaylistExtras(Map<String, dynamic>? newExtras) {
    extras = newExtras;
    _isShow = extras?["episode"] != null;
    mediaId = extras?["mediaId"] ?? 0;
    init = true;

    if (_isShow) {
      episode = extras!["episode"];
      _showData = (TMDB.tvShow(mediaId), TMDB.tvEpisode(mediaId, episode.seasonNumber, episode.episodeNumber)).wait;
      _nextUpEpisode = nextUpEpisode();
    } else {
      _movie = TMDB.movie(mediaId);
    }

    _discordSub?.cancel();
    _setupDiscordSub();
  }

  void _setupDiscordSub() {
    final stream$ = Rx.combineLatest2<bool, Duration, (bool, Duration)>(
      player.stream.playing.startWith(player.state.playing),
      player.stream.duration.startWith(player.state.duration),
      (playing, duration) => (playing, duration),
    ).where((data) => data.$2 > Duration.zero).distinct();

    _discordSub = stream$.listen((data) {
      if (_isShow) {
        _showData.then((show) {
          Discord.updateStatus(
            show.$1.name,
            '${show.$2.seasonNumber}x${show.$2.episodeNumber} ${show.$2.name}',
            player.state.position,
            data.$2,
            show.$2.stillUrl!,
            data.$1,
          );
        });
      } else {
        _movie.then((movie) {
          Discord.updateStatus(
            '${movie.title} (${movie.releaseDate.year})',
            movie.genres.map((item) => item.name).join(', '),
            player.state.position,
            data.$2,
            movie.images?.posters.first.url ?? '',
            data.$1,
          );
        });
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onMouseMove({bool toggle = false}) {
    if (!_showControls) {
      setState(() => _showControls = true);
      _startHideTimer();
    } else if (toggle) {
      setState(() => _showControls = false);
      _hideTimer?.cancel();
    }
  }

  Future<TmdbEpisode?> nextUpEpisode() async {
    TmdbShow show = (await _showData).$1;
    TmdbEpisode? nextEp;
    var realSeason = show.seasons.firstWhere((s) => s.seasonNumber == episode.seasonNumber);
    if (realSeason.episodeCount <= episode.episodeNumber) {
      if (show.seasons.length <= episode.seasonNumber) {
        return null;
      }
      nextEp = await TMDB.tvEpisode(mediaId, episode.seasonNumber + 1, 1);
    } else {
      nextEp = await TMDB.tvEpisode(mediaId, episode.seasonNumber, episode.episodeNumber + 1);
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
    _discordSub?.cancel();
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
        onExit: (_) => setState(() => _showControls = false),
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: TickerMode(enabled: _showControls, child: _buildControlsBar()),
            ),
            SeekIndicator(visible: _showLeftSeek, seconds: _leftSeekSeconds, isLeft: true),
            SeekIndicator(visible: _showRightSeek, seconds: _rightSeekSeconds, isLeft: false),
          ],
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
                        Icon(size: Misc.normalIconSize, LucideIcons.chevronLeft),
                        Text(style: Misc.normalTextStyle, "Return"),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: FutureBuilder(
                    future: _isShow ? _showData : _movie,
                    builder: (context, snapshot) {
                      return Column(
                        spacing: 8,
                        children: [
                          Text(
                            style: Misc.normalTextStyle,
                            snapshot.hasData
                                ? _isShow
                                      ? (snapshot.data! as (TmdbShow, TmdbEpisode)).$1.name
                                      : (snapshot.data! as TmdbMovie).title
                                : "Example Media Name",
                          ),
                          if (_isShow)
                            Text(
                              style: Misc.normalTextStyle,
                              snapshot.hasData
                                  ? "${(snapshot.data! as (TmdbShow, TmdbEpisode)).$2.seasonNumber}x${(snapshot.data! as (TmdbShow, TmdbEpisode)).$2.episodeNumber} ${(snapshot.data! as (TmdbShow, TmdbEpisode)).$2.name}"
                                  : "Example Episode Name",
                            ),
                        ],
                      ).asSkeleton(snapshot: snapshot);
                    },
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ControlButton(icon: Icon(size: Misc.normalIconSize, LucideIcons.info)),
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
                    icon: Icon(size: Misc.normalIconSize, player.state.playing ? LucideIcons.pause : LucideIcons.play),
                  ),
                  if (!Api.isMobile()) VolumeButton(player: player),
                  PositionDisplay(player: player, visible: _showControls),
                  if (_isShow) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 2),
                    Row(
                      spacing: 8,
                      children: [
                        Text(style: Misc.normalTextStyle, 'S${episode.seasonNumber}'),
                        Text(style: Misc.normalTextStyle, 'E${episode.episodeNumber}'),
                      ],
                    ),
                    const Spacer(),
                    EpisodeDrawer(showData: _showData, tmdbId: mediaId),
                    ControlButton(
                      onTap: () async {
                        _playNextEpisode();
                      },
                      icon: Icon(size: Misc.normalIconSize, LucideIcons.skipForward),
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
                    icon: Icon(size: Misc.normalIconSize, false ? RadixIcons.exitFullScreen : RadixIcons.enterFullScreen),
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
