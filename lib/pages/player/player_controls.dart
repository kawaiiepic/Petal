import 'dart:async';

import 'package:flutter/material.dart' as Material;
import 'package:petal/api/api.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/pages/player/player_old.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

Widget customVideoControls(Player player, StreamPlayerState widgetState) {
  return PlayerControls(player: player, widgetState: widgetState);
}

class PlayerControls extends StatefulWidget {
  final Player player;
  final StreamPlayerState widgetState;

  static final normalTextStyle = TextStyle(fontSize: 15.sp.clamp(14, 20));
  static final normalIconSize = 15.px.clamp(14, 20).toDouble();

  const PlayerControls({super.key, required this.player, required this.widgetState});

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
  late final StreamSubscription<(bool, Duration)> _discordSub;

  void _seekBackward() {
    final newPosition = widget.player.state.position - const Duration(seconds: 10);
    widget.player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);

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
    final duration = widget.player.state.duration;
    final newPosition = widget.player.state.position + const Duration(seconds: 10);
    widget.player.seek(newPosition > duration ? duration : newPosition);

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
    TmdbEpisode? nextEpisode = await _nextUpEpisode;
    if (nextEpisode != null) {
      context.pushReplacement('/player?show=${widget.widgetState.widget.showId}&s=${nextEpisode.seasonNumber}&e=${nextEpisode.episodeNumber}');
    }
  }

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _isShow = widget.widgetState.widget.showId != null;

    _nextUpEpisode = nextUpEpisode();

    widget.player.stream.log.listen((log) {
      debugPrint('[${log.level}] ${log.prefix}: ${log.text}');
    });

    if (_isShow) {
      final show = widget.widgetState.widget;
      final episode = show.episode!;
      _showData = (TMDB.tvShow(show.showId!), TMDB.tvEpisode(show.showId!, episode.seasonNumber, episode.episodeNumber)).wait;
    } else {
      _movie = TMDB.movie(widget.widgetState.widget.movieId!);
    }

    if (_isShow) {
      _discordSub =
          Rx.combineLatest2<bool, Duration, (bool, Duration)>(
                widget.player.stream.playing.startWith(widget.player.state.playing),
                widget.player.stream.duration.startWith(widget.player.state.duration),
                (playing, duration) => (playing, duration),
              )
              .where((data) => data.$2 > Duration.zero) // ignore until duration is actually loaded
              .distinct()
              .listen((data) {
                _showData.then((show) {
                  print("Updating Discord Status");
                  Discord.updateStatus(
                    show.$1.name,
                    '${show.$2.seasonNumber}x${show.$2.episodeNumber} ${show.$2.name}',
                    widget.player.state.position,
                    data.$2, // the just-loaded, real duration
                    show.$2.stillUrl!,
                    data.$1,
                  );
                });
              });
    }

    // player = widget.state.widget.controller.player;

    // isShow = widget.widgetState.widget.showId != null;

    // isLoaded.addListener(() {
    //   if (isLoaded.value) {
    //     if (isShow) {
    //       _showData.then((data) async {
    //         final TmdbShow tmdbShow = data[0];
    //         final TmdbEpisode tmdbEpisode = data[1];
    //         print("Updating Discord Status");
    //         Discord.updateStatus(tmdbShow.name, tmdbEpisode.name, player.state.position, player.state.duration, tmdbEpisode.stillUrl!, player.state.playing);
    //       });
    //     }
    //   }
    // });

    // if (isShow) {
    //   _showData = Future.wait([
    //     TMDB.tvShow(widget.widgetState.widget.showId!),
    //     TMDB.tvEpisode(widget.widgetState.widget.showId!, widget.widgetState.widget.episode!.seasonNumber, widget.widgetState.widget.episode!.episodeNumber),
    //   ]);

    //   _showData.then((showData) {
    //     _selectedSeason = ((showData[0] as TmdbShow).seasons.firstWhere((s) => s.seasonNumber == widget.widgetState.widget.episode!.seasonNumber));
    //     if (TraktApi.authState.traktConnected) {
    //       TraktApi.startWatching(MediaType.show, {
    //         "progress": 0.0,
    //         "episode": {
    //           "ids": {"tmdb": (showData[1] as TmdbEpisode).id},
    //         },
    //       });
    //     }
    //   });

    //   _nextEpisode = nextUpEpisode();
    // } else {
    //   movie = TMDB.movie(widget.widgetState.widget.movieId!);
    // }

    // player.stream.buffering.listen((buffering) {
    //   setState(() {
    //     isBuffering = buffering;

    //     if (!isLoaded.value && !buffering) {
    //       isLoaded.value = true;
    //     }
    //   });
    // });
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

  Widget _buildSeekIndicator({required bool visible, required int seconds, required bool isLeft}) {
    return IgnorePointer(
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: visible ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isLeft ? Icons.replay_10_rounded : Icons.forward_10_rounded, color: Colors.white, size: 28),
                    if (seconds > 10) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${seconds}s',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // String formatDurationShort(Duration duration) {
  //   final minutes = duration.inMinutes;
  //   final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  //   return '$minutes:$seconds';
  // }

  Future<TmdbEpisode?> nextUpEpisode() async {
    print('Geting next episode');
    var showId = widget.widgetState.widget.showId;
    var season = widget.widgetState.widget.episode!.seasonNumber;
    var episode = widget.widgetState.widget.episode!.episodeNumber;

    TmdbShow show = (await _showData).$1;
    TmdbEpisode? nextEp;
    var realSeason = show.seasons.firstWhere((s) => s.seasonNumber == season);
    if (realSeason.episodeCount <= episode) {
      if (show.seasons.length <= season) {
        return null;
      }
      nextEp = await TMDB.tvEpisode(showId!, season + 1, 1);
    } else {
      nextEp = await TMDB.tvEpisode(showId!, season, episode + 1);
    }

    final airDate = DateTime.parse(nextEp.airDate);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (airDate.isBefore(todayOnly)) {
      return nextEp;
    }

    return null;
  }

  @override
  void dispose() {
    // _positonTimer?.cancel();
    // _uiTimer?.cancel();
    _leftSeekTimer?.cancel();
    _rightSeekTimer?.cancel();
    _hideTimer?.cancel();
    _discordSub.cancel();
    super.dispose();
  }

  // void restartUi({bool toggle = false}) {
  //   if (toggle && _uiIsActive == true) {
  //     setState(() {
  //       _uiIsActive = false;
  //     });

  //     widget.state.setSubtitleViewPadding(widget.state.widget.subtitleViewConfiguration.padding);
  //     _uiTimer?.cancel();
  //     return;
  //   }
  //   if (_uiIsActive == false) {
  //     setState(() {
  //       _uiIsActive = true;
  //     });

  //     widget.state.setSubtitleViewPadding(EdgeInsets.fromLTRB(0, 0, 0, 100) + widget.state.widget.subtitleViewConfiguration.padding);
  //   }

  //   _uiTimer?.cancel();
  //   _uiTimer = Timer.periodic(Duration(milliseconds: 5500), (timer) {
  //     if (isPlaying && isLoaded.value && overlayInt == 0) {
  //       setState(() {
  //         _uiIsActive = false;
  //       });
  //       widget.state.setSubtitleViewPadding(widget.state.widget.subtitleViewConfiguration.padding);
  //       timer.cancel();
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
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
        print('Tessting');
        _onMouseMove(toggle: true);
      },
      child: MouseRegion(
        // hitTestBehavior: HitTestBehavior.deferToChild,
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
            _buildSeekIndicator(visible: _showLeftSeek, seconds: _leftSeekSeconds, isLeft: true),
            _buildSeekIndicator(visible: _showRightSeek, seconds: _rightSeekSeconds, isLeft: false),
            if (_isShow)
              Positioned(
                right: 20,
                bottom: 40,
                child: _NextUpCard(player: widget.player, nextEpisode: _nextUpEpisode, uiIsActive: _showControls, playNextEpisode: _playNextEpisode),
              ),
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
                        Icon(size: PlayerControls.normalIconSize, Icons.arrow_back_ios_new_rounded),
                        Text(style: PlayerControls.normalTextStyle, "Return"),
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
                            style: PlayerControls.normalTextStyle,
                            snapshot.hasData
                                ? _isShow
                                      ? (snapshot.data! as (TmdbShow, TmdbEpisode)).$1.name
                                      : (snapshot.data! as TmdbMovie).title
                                : "Example Media Name",
                          ),
                          if (_isShow)
                            Text(
                              style: PlayerControls.normalTextStyle,
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
                  child: ControlButton(icon: Icon(size: PlayerControls.normalIconSize, Icons.info_outline_rounded)),
                ),
              ),
            ],
          ),
          Center(child: _PlayPauseButton(player: widget.player)),

          Column(
            spacing: 8,
            children: [
              RepaintBoundary(
                child: _Slider(player: widget.player, visible: _showControls),
              ),
              Row(
                spacing: 8,
                children: [
                  ControlButton(
                    onTap: () => setState(() {
                      widget.player.playOrPause();
                    }),
                    icon: Icon(size: PlayerControls.normalIconSize, widget.player.state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  if (!Api.isMobile()) VolumeButton(player: widget.player),
                  _PositionDisplay(player: widget.player, visible: _showControls),
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
                        Text(style: PlayerControls.normalTextStyle, 'S${widget.widgetState.widget.episode!.seasonNumber}'),
                        Text(style: PlayerControls.normalTextStyle, 'E${widget.widgetState.widget.episode!.episodeNumber}'),
                      ],
                    ),

                    const Spacer(),

                    _EpisodeDrawer(showData: _showData, tmdbId: widget.widgetState.widget.showId!),
                    ControlButton(
                      onTap: () async {
                        _playNextEpisode();
                      },
                      icon: Icon(size: PlayerControls.normalIconSize, Icons.skip_next_rounded),
                    ),
                  ],

                  DropdownButton(
                    dropdownMenu: DropdownMenu(
                      children: [
                        MenuLabel(
                          child: Row(
                            children: [
                              ControlButton(icon: Icon(size: PlayerControls.normalIconSize, Icons.arrow_back_ios_new_rounded)),
                              Icon(size: PlayerControls.normalIconSize, Icons.subtitles_rounded),
                              Text(style: PlayerControls.normalTextStyle, 'Subtitles'),
                              const Spacer(),
                              ControlButton(icon: Icon(size: PlayerControls.normalIconSize, Icons.upload_rounded)),
                            ],
                          ),
                        ),
                        const MenuDivider(),
                        MenuLabel(
                          child: Collapsible(
                            children: [
                              CollapsibleTrigger(child: Text(style: PlayerControls.normalTextStyle, 'Subtitles')),
                              Text(style: PlayerControls.normalTextStyle, widget.player.state.track.subtitle.language ?? 'None').withPadding(left: 30),
                              ...widget.player.state.tracks.subtitle.map(
                                (e) => CollapsibleContent(
                                  child: MenuButton(
                                    onPressed: (context) => setState(() {
                                      widget.player.setSubtitleTrack(e);
                                    }),
                                    child: Text(style: PlayerControls.normalTextStyle, e.language ?? e.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        MenuLabel(
                          child: Collapsible(
                            children: [
                              CollapsibleTrigger(child: Text(style: PlayerControls.normalTextStyle, 'Audio Track')),
                              Text(style: PlayerControls.normalTextStyle, widget.player.state.track.audio.language ?? 'None').withPadding(left: 30),
                              ...widget.player.state.tracks.audio.map(
                                (e) => CollapsibleContent(
                                  child: MenuButton(
                                    onPressed: (context) => setState(() {
                                      widget.player.setAudioTrack(e);
                                    }),
                                    child: Text(style: PlayerControls.normalTextStyle, e.language ?? e.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    icon: Icon(size: PlayerControls.normalIconSize, Icons.subtitles_rounded),
                  ),

                  DropdownButton(
                    dropdownMenu: DropdownMenu(
                      children: [
                        MenuLabel(
                          child: Row(
                            spacing: 8,
                            children: [
                              ControlButton(icon: Icon(size: PlayerControls.normalIconSize, Icons.arrow_back_ios_new_rounded)),
                              Icon(size: PlayerControls.normalIconSize, Icons.settings_rounded),
                              Text(style: PlayerControls.normalTextStyle, 'Settings'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    icon: Icon(size: PlayerControls.normalIconSize, Icons.settings_rounded),
                  ),

                  ControlButton(
                    onTap: () {
                      widget.widgetState.setState(() {
                        widget.widgetState.zoomVideo = !widget.widgetState.zoomVideo;
                      });
                      // windowManager.setFullScreen(!(await windowManager.isFullScreen()));
                    },
                    icon: Icon(size: PlayerControls.normalIconSize, widget.widgetState.zoomVideo ? Icons.fullscreen_exit : Icons.fullscreen_rounded),
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

class ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const ControlButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(variance: ButtonVariance.ghost, onPressed: onTap, icon: icon);
}

class DropdownButton extends StatelessWidget {
  final Widget icon;
  final DropdownMenu dropdownMenu;
  const DropdownButton({super.key, required this.icon, required this.dropdownMenu});

  @override
  Widget build(BuildContext context) => IconButton(
    variance: ButtonVariance.ghost,
    onPressed: () {
      showDropdown(context: context, consumeOutsideTaps: true, alignment: Alignment.topCenter, builder: (context) => dropdownMenu);
    },
    icon: icon,
  );
}

class _EpisodeDrawer extends StatefulWidget {
  final Future<(TmdbShow, TmdbEpisode)> showData;
  final int tmdbId;

  const _EpisodeDrawer({required this.showData, required this.tmdbId});

  @override
  State<_EpisodeDrawer> createState() => _EpisodeDrawerState();
}

class _EpisodeDrawerState extends State<_EpisodeDrawer> {
  SeasonSummary? _selectedSeason;
  final Map<int, Future<TmdbSeason>> _loadedSeasons = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ControlButton(
      onTap: () {
        showOverlay(
          context,
          DrawerConfiguration(
            expands: true,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    FutureBuilder(
                      future: widget.showData,
                      builder: (context, snapshot) {
                        if (_selectedSeason == null && snapshot.hasData) {
                          _selectedSeason = snapshot.data!.$1.seasons.firstWhere((s) => s.seasonNumber == snapshot.data!.$2.seasonNumber);
                        }
                        return Select<SeasonSummary>(
                          itemBuilder: (context, item) => Text(style: PlayerControls.normalTextStyle, _selectedSeason?.name ?? ''),
                          popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
                          onChanged: (value) {
                            setState(() => _selectedSeason = value);
                          },
                          value: _selectedSeason,
                          placeholder: Text(style: PlayerControls.normalTextStyle, 'Select a season'),
                          popup: SelectPopup(
                            items: SelectItemList(
                              children: snapshot.hasData
                                  ? snapshot.data!.$1.seasons
                                        .map(
                                          (s) => SelectItemButton(
                                            value: s,
                                            child: Text(style: PlayerControls.normalTextStyle, s.name),
                                          ),
                                        )
                                        .toList()
                                  : [],
                            ),
                          ).call,
                        );
                      },
                    ),
                    FutureBuilder(
                      future: _loadedSeasons.putIfAbsent(
                        _selectedSeason?.seasonNumber ?? 0,
                        () => TMDB.tvSeason(widget.tmdbId, _selectedSeason?.seasonNumber ?? 0),
                      ),
                      builder: (context, snapshot) {
                        return snapshot.hasData
                            ? Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: snapshot.data!.episodes
                                      .map(
                                        (episode) => Padding(
                                          padding: EdgeInsetsGeometry.fromLTRB(0, 4, 0, 4),
                                          child: GhostButton(
                                            onPressed: () {
                                              context.pushReplacement('/player?show=${widget.tmdbId}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                            },
                                            child: Row(
                                              spacing: 12,
                                              children: [
                                                if (episode.stillPath != null)
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.network(
                                                      'https://image.tmdb.org/t/p/w300${episode.stillPath}',
                                                      width: 120,
                                                      height: 68,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    spacing: 8,
                                                    children: [
                                                      Text(
                                                        style: PlayerControls.normalTextStyle.copyWith(fontSize: 13.sp),
                                                        '${episode.episodeNumber}. ${episode.name}',
                                                      ),
                                                      Text(
                                                        style: PlayerControls.normalTextStyle.copyWith(fontSize: 13.sp),
                                                        episode.overview,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      icon: Icon(size: PlayerControls.normalIconSize, Icons.amp_stories_rounded),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final Player player;
  const _PlayPauseButton({required this.player});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
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
      onTap: () => widget.player.playOrPause(), // no setState here
      icon: _buffering ? CircularProgressIndicator(size: 50) : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 50),
    );
  }
}

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
              size: PlayerControls.normalIconSize,
              _volume == 0
                  ? Icons.volume_off_rounded
                  : _volume < 50
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded,
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

class _Slider extends StatefulWidget {
  final Player player;
  final bool visible;
  const _Slider({required this.player, required this.visible});

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  double? _dragValue;
  bool _isDragging = false;
  Duration _position = Duration.zero;
  Duration _buffer = Duration.zero;
  StreamSubscription<Duration>? _sub;
  StreamSubscription<Duration>? _bufferSub;

  @override
  void initState() {
    super.initState();
    _position = widget.player.state.position;
    _buffer = widget.player.state.buffer;
    _sub = widget.player.stream.position.throttleTime(const Duration(seconds: 3)).listen(_onPosition);
    _bufferSub = widget.player.stream.buffer.throttleTime(const Duration(seconds: 5)).listen(_onBufferPosition);
  }

  void _onPosition(Duration position) {
    _position = position;
    if (widget.visible && mounted) {
      setState(() {}); // only rebuild while actually shown
    }
  }

  void _onBufferPosition(Duration position) {
    _buffer = position;
    if (widget.visible && mounted) {
      setState(() {}); // only rebuild while actually shown
    }
  }

  @override
  void didUpdateWidget(covariant _Slider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() {}); // catch up once, right as controls reappear
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _bufferSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.player.state.duration;
    final buffer = widget.player.state.buffer;
    double liveValue = 0;
    double liveValueBuffer = 0;
    if (duration.inSeconds > 0) {
      liveValue = (_position.inSeconds / duration.inSeconds).clamp(0, 1);
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
        widget.player.seek(Duration(milliseconds: (v.value * duration.inMilliseconds).toInt()));
        setState(() {
          _isDragging = false;
          _dragValue = null;
        });
      },
    );
  }
}

// Separate widget that only rebuilds itself
class _PositionDisplay extends StatefulWidget {
  final Player player;
  final bool visible;
  const _PositionDisplay({required this.player, required this.visible});

  @override
  State<_PositionDisplay> createState() => _PositionDisplayState();
}

class _PositionDisplayState extends State<_PositionDisplay> {
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
  void didUpdateWidget(covariant _PositionDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() {}); // catch up once controls reappear
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
        Text(style: PlayerControls.normalTextStyle, Misc.fmt(_position)),
        Text(style: PlayerControls.normalTextStyle, '/'),
        Text(style: PlayerControls.normalTextStyle, Misc.fmt(widget.player.state.duration)),
      ],
    ),
  );
}

class _NextUpCard extends StatefulWidget {
  final Player player;
  final Future<TmdbEpisode?> nextEpisode;
  final Function playNextEpisode;
  final bool uiIsActive;

  const _NextUpCard({required this.player, required this.nextEpisode, required this.uiIsActive, required this.playNextEpisode});

  @override
  Material.State<Material.StatefulWidget> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<_NextUpCard> {
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
        bool _dismissed = false;
        final showCard = nearEnd && !_dismissed;

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
                                errorWidget: (_, __, ___) => const Center(child: Text('Image missing')),
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
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
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
                                  print("Close");
                                  _timer?.cancel();
                                  setState(() {
                                    _started = false;
                                    _secondsLeft = _maxtime;
                                  });
                                },
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
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
