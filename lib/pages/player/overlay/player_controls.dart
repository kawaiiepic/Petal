import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/models/custom_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/splash.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

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

    // Handle the case where the playlist is already loaded
    final currentPlaylist = player.state.playlist;
    if (currentPlaylist.medias.isNotEmpty) {
      _onPlaylistExtras(currentPlaylist.medias[currentPlaylist.index].extras);
    }

    // And handle future changes
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
      print("is a show");
      episode = extras!["episode"];
      _showData = (TMDB.tvShow(mediaId), TMDB.tvEpisode(mediaId, episode.seasonNumber, episode.episodeNumber)).wait;
      _nextUpEpisode = nextUpEpisode();
    } else {
      _movie = TMDB.movie(mediaId);
    }

    _discordSub?.cancel(); // avoid duplicate/leaked subscriptions on re-entry
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
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isLeft ? LucideIcons.rewind : LucideIcons.fastForward, color: Colors.white, size: 28),
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

  Future<TmdbEpisode?> nextUpEpisode() async {
    print('Geting next episode');

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
    // _positonTimer?.cancel();
    // _uiTimer?.cancel();
    _leftSeekTimer?.cancel();
    _rightSeekTimer?.cancel();
    _hideTimer?.cancel();
    _discordSub?.cancel();
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
            _buildSeekIndicator(visible: _showLeftSeek, seconds: _leftSeekSeconds, isLeft: true),
            _buildSeekIndicator(visible: _showRightSeek, seconds: _rightSeekSeconds, isLeft: false),
            // if (_isShow)
            //   Positioned(
            //     right: 20,
            //     bottom: 40,
            //     child: _NextUpCard(player: player, nextEpisode: _nextUpEpisode, uiIsActive: _showControls, playNextEpisode: _playNextEpisode),
            //   ),
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
          Center(child: _PlayPauseButton(player: player)),

          Column(
            spacing: 8,
            children: [
              RepaintBoundary(
                child: _Slider(player: player, visible: _showControls),
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
                  _PositionDisplay(player: player, visible: _showControls),
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

                    _EpisodeDrawer(showData: _showData, tmdbId: mediaId),
                    ControlButton(
                      onTap: () async {
                        _playNextEpisode();
                      },
                      icon: Icon(size: Misc.normalIconSize, LucideIcons.skipForward),
                    ),
                  ],

                  if (!_isShow) ...[const Spacer()],

                  DropdownButton(
                    dropdownMenu: DropdownMenu(
                      children: [
                        MenuLabel(
                          child: Row(
                            children: [
                              Icon(size: Misc.normalIconSize, LucideIcons.typeOutline),
                              Text(style: Misc.normalTextStyle, 'Subtitles'),
                              const Spacer(),
                              ControlButton(icon: Icon(size: Misc.normalIconSize, LucideIcons.upload)),
                            ],
                          ),
                        ),
                        const MenuDivider(),
                        MenuLabel(
                          child: Collapsible(
                            children: [
                              CollapsibleTrigger(child: Text(style: Misc.normalTextStyle, 'Subtitles')),
                              Text(style: Misc.normalTextStyle, player.state.track.subtitle.language ?? 'None').withPadding(left: 30),
                              ...player.state.tracks.subtitle
                                  .where((a) => a.id != "auto" && a.id != "no")
                                  .map(
                                    (e) => CollapsibleContent(
                                      child: MenuButton(
                                        onPressed: (context) => setState(() {
                                          player.setSubtitleTrack(e);
                                        }),
                                        child: Text(style: Misc.normalTextStyle, e.title ?? e.language ?? e.id),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        MenuLabel(
                          child: Collapsible(
                            children: [
                              CollapsibleTrigger(child: Text(style: Misc.normalTextStyle, 'Audio Track')),
                              Text(style: Misc.normalTextStyle, player.state.track.audio.language ?? 'None').withPadding(left: 30),
                              ...player.state.tracks.audio
                                  .where((a) => a.id != "auto" && a.id != "no")
                                  .map(
                                    (e) => CollapsibleContent(
                                      child: MenuButton(
                                        onPressed: (context) => setState(() {
                                          player.setAudioTrack(e);
                                        }),
                                        child: Text(style: Misc.normalTextStyle, e.title ?? e.language ?? e.id),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    icon: Icon(size: Misc.normalIconSize, LucideIcons.typeOutline),
                  ),

                  DropdownButton(
                    dropdownMenu: DropdownMenu(
                      children: [
                        MenuLabel(
                          child: Row(
                            spacing: 8,
                            children: [
                              Icon(size: Misc.normalIconSize, LucideIcons.settings2),
                              Text(style: Misc.normalTextStyle, 'Settings'),
                            ],
                          ),
                        ),

                        MenuDivider(),

                        MenuButton(
                          child: Text('Take Screenshot'),
                          onPressed: (context) async {
                            final Uint8List? screenshot = await player.screenshot();
                          },
                        ),
                      ],
                    ),
                    icon: Icon(size: Misc.normalIconSize, LucideIcons.settings2),
                  ),

                  ControlButton(
                    onTap: () {
                      // windowManager.setFullScreen(!(await windowManager.isFullScreen()));
                    },
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
    initSeason();
  }

  Future<void> initSeason() async {
    final data = await widget.showData;
    _selectedSeason = data.$1.seasons.firstWhere((s) => s.seasonNumber == data.$2.seasonNumber);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayAnchor(
      anchor: #outerDrawerButton,
      child: ControlButton(
        onTap: () {
          showOverlay(
            context,
            DrawerConfiguration(anchor: LinkedAnchor(#outerDrawerButton), expands: true),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    FutureBuilder(
                      future: widget.showData,
                      builder: (context, snapshot) {
                        return DrawerOverlay(
                          child: OverlayAnchor(
                            anchor: #select,
                            child: Select<SeasonSummary>(
                              overlayConfiguration: PopoverConfiguration(alignment: AlignmentGeometry.center, anchor: LinkedAnchor(#select)),
                              itemBuilder: (context, item) => Text(style: Misc.normalTextStyle, _selectedSeason?.name ?? ''),
                              // popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
                              onChanged: (value) {
                                setState(() => _selectedSeason = value);
                              },
                              value: _selectedSeason,
                              placeholder: Text(style: Misc.normalTextStyle, 'Select a season'),
                              popup: SelectPopup(
                                items: SelectItemList(
                                  children: snapshot.hasData
                                      ? snapshot.data!.$1.seasons
                                            .map(
                                              (s) => SelectItemButton(
                                                value: s,
                                                child: Text(style: Misc.normalTextStyle, s.name),
                                              ),
                                            )
                                            .toList()
                                      : [],
                                ),
                              ),
                            ),
                          ),
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
                                              context.pushReplacement('/player?media=${widget.tmdbId}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
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
                                                      Text(style: Misc.normalTextStyle.copyWith(fontSize: 13.sp), '${episode.episodeNumber}. ${episode.name}'),
                                                      Text(
                                                        style: Misc.normalTextStyle.copyWith(fontSize: 13.sp),
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
          );
        },
        icon: Icon(size: Misc.normalIconSize, LucideIcons.listOrdered),
      ),
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
      icon: _buffering ? CircularProgressIndicator(size: 50) : Icon(_playing ? LucideIcons.pause : LucideIcons.play, size: 50),
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

class _Slider extends StatefulWidget {
  final Player player;
  final bool visible;
  const _Slider({required this.player, required this.visible});

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> with SingleTickerProviderStateMixin {
  double? _dragValue;
  bool _isDragging = false;

  // Real, authoritative values (updated rarely, via throttled stream)
  Duration _syncedPosition = Duration.zero;
  Duration _buffer = Duration.zero;

  // Local clock used to interpolate between syncs
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

    // Real position sync — corrects drift, doesn't drive the UI directly
    _sub = widget.player.stream.position.throttleTime(const Duration(seconds: 3)).listen(_onPosition);

    _bufferSub = widget.player.stream.buffer.throttleTime(const Duration(seconds: 5)).listen(_onBufferPosition);

    _playingSub = widget.player.stream.playing.listen((playing) {
      _playing = playing;
      // resync clock so no jump happens when play/pause toggles
      _resync(_interpolatedPosition);
    });

    // Ticks every frame; cheap no-op when not playing/not visible
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
      setState(() {}); // only rebuild while actually shown
    }
  }

  void _resync(Duration position) {
    _syncedPosition = position;
    _stopwatch
      ..reset()
      ..start();
  }

  void _onPosition(Duration position) {
    // Correct any drift from the interpolation with the real value
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
  void didUpdateWidget(covariant _Slider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() {}); // catch up once, right as controls reappear
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
        _resync(target); // avoid snapping back to stale position before next real update
        _interpolatedPosition = target;
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
        Text(style: Misc.normalTextStyle, Misc.fmt(_position)),
        Text(style: Misc.normalTextStyle, '/'),
        Text(style: Misc.normalTextStyle, Misc.fmt(widget.player.state.duration)),
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
  State<StatefulWidget> createState() => _NextUpCardState();
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
                                  print("Close");
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
