import 'dart:async';

import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/tmdb/tmdb_models.dart';
import 'package:blssmpetal/pages/player/player_old.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pip_plugin/pip_plugin.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:window_manager/window_manager.dart';

Widget customVideoControls(VideoState state, StreamPlayer widget) {
  return PlayerControls(state: state, widget: widget);
}

class PlayerControls extends StatefulWidget {
  final VideoState state;
  final StreamPlayer widget;
  const PlayerControls({super.key, required this.state, required this.widget});

  @override
  State<StatefulWidget> createState() => _PlayerControls();
}

class _PlayerControls extends State<PlayerControls> {
  bool _uiIsActive = false;
  late Player player;
  bool isPlaying = false;
  bool isBuffering = true;
  late bool isShow;

  late Future<List<dynamic>> _showData;
  late Future movie;
  Timer? _positonTimer;
  Timer? _uiTimer;

  Duration position = Duration();
  Duration buffer = Duration();
  Duration duration = Duration();

  PipPlugin pip = PipPlugin();

  int? _selectedSeason;
  late Future<TmdbEpisode?> _nextEpisode;

  @override
  void initState() {
    super.initState();

    isShow = widget.widget.showId != null;

    if (isShow) {
      _selectedSeason = widget.widget.episode!.seasonNumber;
      _showData = Future.wait([
        TMDB.tvShow(widget.widget.showId!),
        TMDB.tvEpisode(widget.widget.showId!, widget.widget.episode!.seasonNumber, widget.widget.episode!.episodeNumber),
      ]);
      _nextEpisode = nextUpEpisode();
    } else {
      movie = TMDB.movie(widget.widget.movieId!);
    }

    player = widget.state.widget.controller.player;
    duration = widget.state.widget.controller.player.state.duration;

    player.stream.buffering.listen((buffering) {
      setState(() {
        isBuffering = buffering;
      });
    });

    _positonTimer = Timer.periodic(Duration(milliseconds: 200), (_) {
      if (mounted) {
        setState(() {
          position = player.state.position; // always refresh
          duration = player.state.duration;
        });
      }
    });

    player.stream.playing.listen((playing) {
      isPlaying = playing;
    });

    player.stream.buffer.listen((buffer) {
      setState(() {
        this.buffer = buffer;
      });
    });
  }

  String formatDurationShort(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<TmdbEpisode?> nextUpEpisode() async {
    var showId = widget.widget.showId;
    var season = widget.widget.episode!.seasonNumber;
    var episode = widget.widget.episode!.episodeNumber;
    TmdbShow show = (await _showData)[0];
    if (show.seasons[season].episodeCount <= episode) {
      if (show.seasons.length <= season) {
        return null;
      }
      return TMDB.tvEpisode(showId!, season + 1, episode + 1);
    } else {
      return TMDB.tvEpisode(showId!, season, episode + 1);
    }
  }

  @override
  void dispose() {
    _positonTimer?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: _uiIsActive ? SystemMouseCursors.basic : SystemMouseCursors.none,
    onHover: (event) {
      setState(() {
        _uiIsActive = true;
      });

      widget.state.setSubtitleViewPadding(EdgeInsets.fromLTRB(0, 0, 0, 100) + widget.state.widget.subtitleViewConfiguration.padding);

      _uiTimer?.cancel();
      _uiTimer = Timer(Duration(milliseconds: 5500), () {
        setState(() {
          _uiIsActive = false;
        });
        widget.state.setSubtitleViewPadding(widget.state.widget.subtitleViewConfiguration.padding);
      });
    },
    child: Stack(
      alignment: AlignmentGeometry.bottomRight,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              widget.state.widget.controller.player.playOrPause();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(),
          ),
        ),

        // Controls overlay
        AnimatedOpacity(
          opacity: _uiIsActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      variance: ButtonVariance.ghost,
                      onPressed: () {
                        context.pop();
                      },
                      icon: Row(children: [Icon(Icons.arrow_back_ios_new_rounded), Text("Return")]),
                    ),
                    if (isShow)
                      FutureBuilder(
                        future: _showData,
                        builder: (context, snapshot) => Column(
                          spacing: 8,
                          children: [
                            Text(snapshot.hasData ? (snapshot.data![0] as TmdbShow).name : 'Example Show Name'),
                            Text(snapshot.hasData ? (snapshot.data![1] as TmdbEpisode).name : 'Example Episode Name'),
                          ],
                        ).asSkeleton(snapshot: snapshot),
                      )
                    else
                      FutureBuilder(
                        future: movie,
                        builder: (context, snapshot) => snapshot.hasData ? Text((snapshot.data! as TmdbMovie).title) : const SizedBox.shrink(),
                      ),
                    ControlButton(icon: Icon(Icons.info_outline_rounded)),
                  ],
                ),
                Center(
                  child: ControlButton(
                    onTap: () => player.playOrPause(),
                    icon: isBuffering ? CircularProgressIndicator() : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 50),
                  ),
                ),
                Column(
                  spacing: 8,
                  children: [
                    Slider(
                      value: SliderValue.single(duration.inMilliseconds > 0 ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) : 0.0),
                      hintValue: SliderValue.single(duration.inMilliseconds > 0 ? (buffer.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) : 0.0),
                      onChanged: duration.inMilliseconds > 0
                          ? (value) {
                              final newPosition = Duration(milliseconds: (value.value * duration.inMilliseconds).toInt());
                              player.seek(newPosition);
                            }
                          : null,
                    ),
                    Row(
                      children: [
                        ControlButton(onTap: () => player.playOrPause(), icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                        VolumeButton(player: player),
                        Row(spacing: 4, children: [Text(formatDurationShort(position)), Text('/'), Text(formatDurationShort(duration))]),

                        if (isShow) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Row(spacing: 8, children: [Text('S${widget.widget.episode!.seasonNumber}'), Text('E${widget.widget.episode!.episodeNumber}')]),
                        ],

                        const Spacer(),
                        if (isShow)
                          ControlButton(
                            onTap: () {
                              openDrawer(
                                context: context,
                                builder: (context) => _EpisodeDrawer(
                                  showData: _showData,
                                  initialSeason: _selectedSeason,
                                  tmdbId: widget.widget.showId!,
                                  onSeasonChanged: (season) {
                                    setState(() => _selectedSeason = season);
                                  },
                                ),
                                position: OverlayPosition.right,
                              );
                            },
                            icon: Icon(Icons.amp_stories_rounded),
                          ),
                        ControlButton(
                          onTap: () async {
                            TmdbEpisode? nextEpisode = await _nextEpisode;
                            if (nextEpisode != null) {
                              context.pushReplacement('/player?show=${widget.widget.showId}&s=${nextEpisode.seasonNumber}&e=${nextEpisode.episodeNumber}');
                            }
                          },
                          icon: Icon(Icons.skip_next_rounded),
                        ),
                        DropdownButton(
                          dropdownMenu: DropdownMenu(
                            children: [
                              MenuLabel(
                                child: Row(
                                  children: [
                                    ControlButton(icon: Icon(Icons.arrow_back_ios_new_rounded)),
                                    Icon(Icons.subtitles_rounded),
                                    Text('Subtitles'),
                                    Spacer(),
                                    ControlButton(icon: Icon(Icons.upload_rounded)),
                                  ],
                                ),
                              ),
                              MenuDivider(),
                              MenuLabel(child: Text('Subtitle')),
                              ...player.state.tracks.subtitle.map(
                                (e) => MenuButton(onPressed: (context) => player.setSubtitleTrack(e), child: Text(e.language ?? e.id)),
                              ),

                              MenuLabel(child: Text('Audio')),
                              ...player.state.tracks.audio.map(
                                (e) => MenuButton(onPressed: (context) => player.setAudioTrack(e), child: Text(e.language ?? e.id)),
                              ),
                            ],
                          ),
                          icon: Icon(Icons.subtitles_rounded),
                        ),
                        DropdownButton(
                          dropdownMenu: DropdownMenu(
                            children: [
                              MenuLabel(
                                child: Row(
                                  children: [
                                    ControlButton(icon: Icon(Icons.arrow_back_ios_new_rounded)),
                                    Icon(Icons.settings_rounded),
                                    Text('Settings'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          icon: Icon(Icons.settings_rounded),
                        ),
                        ControlButton(
                          onTap: () {
                            pip.setupPip();
                            pip.startPip();
                          },
                          icon: Icon(Icons.picture_in_picture_alt_rounded),
                        ),
                        ControlButton(
                          onTap: () async {
                            windowManager.setFullScreen(!(await windowManager.isFullScreen()));
                          },
                          icon: Icon(Icons.fullscreen_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Positioned(
          right: 20,
          bottom: 40,
          child: AnimatedSlide(
            offset: (duration.inMilliseconds > 0 && (position.inMilliseconds / duration.inMilliseconds) > 0.93) ? Offset(0, -0.10) : Offset.zero,
            duration: const Duration(milliseconds: 500),
            child: AnimatedOpacity(
              opacity: (duration.inMilliseconds > 0 && (position.inMilliseconds / duration.inMilliseconds) > 0.93) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: _uiIsActive ? Offset(0, -0.20) : Offset.zero,
                child: FutureBuilder(
                  future: _nextEpisode,
                  builder: (context, snapshot) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 300,
                      height: 170,
                      child: Stack(
                        // fit: StackFit.expand,
                        children: [
                          snapshot.hasData
                              ? CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w300${snapshot.data!.stillPath}', fit: BoxFit.cover)
                              : Container(width: 120, height: 68, color: Colors.pink),

                          Container(color: Colors.black.withAlpha(120)),

                          Center(
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

                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              // onTap: () => setState(() => disableNextUp = true),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withAlpha(120)),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
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
                                children: [
                                  Text(
                                    "Up Next",
                                    style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    snapshot.hasData ? snapshot.data!.name : 'Example Show Name',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    snapshot.hasData
                                        ? "S${snapshot.data!.seasonNumber}:E${snapshot.data!.episodeNumber} · ${snapshot.data!.name}"
                                        : "Example Episode title and Season info",
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // const SizedBox(height: 8),
                                  LinearProgressIndicator(value: 0.5, minHeight: 8, color: Colors.pink, backgroundColor: Colors.white.withAlpha(60)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
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
      showDropdown(context: context, builder: (context) => dropdownMenu);
    },
    icon: icon,
  );
}

class _EpisodeDrawer extends StatefulWidget {
  final Future<List<dynamic>> showData;
  final int? initialSeason;
  final int tmdbId;
  final void Function(int) onSeasonChanged;

  const _EpisodeDrawer({required this.showData, required this.initialSeason, required this.onSeasonChanged, required this.tmdbId});

  @override
  State<_EpisodeDrawer> createState() => _EpisodeDrawerState();
}

class _EpisodeDrawerState extends State<_EpisodeDrawer> {
  late int? _selectedSeason;
  final Map<int, Future<TmdbSeason>> _loadedSeasons = {};

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.initialSeason;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 800,
      width: 500,
      child: Column(
        children: [
          FutureBuilder(
            future: widget.showData,
            builder: (context, snapshot) {
              return Select<int>(
                itemBuilder: (context, item) => Text('Season $item'),
                popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
                onChanged: (value) {
                  setState(() => _selectedSeason = value);
                  widget.onSeasonChanged(value!);
                },
                value: _selectedSeason,
                placeholder: const Text('Select a season'),
                popup: SelectPopup(
                  items: SelectItemList(
                    children: snapshot.hasData
                        ? (snapshot.data![0] as TmdbShow).seasons.map((s) => SelectItemButton(value: s.seasonNumber, child: Text(s.name))).toList()
                        : [],
                  ),
                ).call,
              );
            },
          ),
          FutureBuilder(
            future: _loadedSeasons.putIfAbsent(_selectedSeason ?? 0, () => TMDB.tvSeason(widget.tmdbId, _selectedSeason ?? 0)),
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
                                            Text('${episode.episodeNumber}. ${episode.name}', style: const TextStyle(fontSize: 15)),
                                            Text(episode.overview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
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
                    width: _hovered ? 60 : 0,
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
                  Gap(_hovered ? 5 : 0)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
