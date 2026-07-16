import 'dart:ui';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/main.dart';
import 'package:petal/models/custom_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/pages/splash.dart';
import 'package:petal/router/router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class EpisodeOverview extends StatefulWidget {
  final int tmdbId;

  const EpisodeOverview({super.key, required this.tmdbId});

  @override
  State<EpisodeOverview> createState() => _EpisodeOverviewState();
}

class _EpisodeOverviewState extends State<EpisodeOverview> {
  late Future<TmdbShow> _tvShow;
  late Future<TmdbSeason> _seasons;

  Episode episode = Episode(seasonNumber: 1, episodeNumber: 1);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tvShow = TMDB.tvShow(widget.tmdbId);
    _seasons = TMDB.tvSeason(widget.tmdbId, episode.seasonNumber);
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null) return '';
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _tvShow,
      builder: (context, showSnapshot) {
        if (showSnapshot.hasData && !showSnapshot.hasError) {
          final show = showSnapshot.data!;
          final router = GoRouter.of(context);

          return Container(
            color: Theme.of(context).colorScheme.background,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  collapsedHeight: 300,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: material.FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Backdrop
                        Image.network(
                          'https://image.tmdb.org/t/p/original${show.images?.backdrops.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),

                        // Bottom gradient so logo + button are readable
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.4)],
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),

                        // Logo — bottom left
                        Positioned(
                          bottom: 100,
                          left: 24,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 80),
                            child: Image.network(
                              'https://image.tmdb.org/t/p/original${show.images?.logos.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull?.filePath}',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Text(show.name),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 24,
                          left: 24,
                          child: Row(
                            spacing: 8,
                            children: [
                              ContextMenu(
                                items: [
                                  MenuButton(
                                    trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true)),
                                    onPressed: (_) {
                                      // router.push('/streams?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                      AppRouter.appRouter.push('/streams?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                    },
                                    child: const Text('Select Source'),
                                  ),
                                ],
                                child: Button(
                                  onPressed: () => router.push('/player?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}'),
                                  style: const ButtonStyle.primary().withBorderRadius(
                                    borderRadius: BorderRadius.circular(16),
                                    hoverBorderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      Icon(Icons.play_arrow_rounded),
                                      Text(
                                        style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 15.sp),
                                        'S${episode.seasonNumber}:E${episode.episodeNumber}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _IconBtn(icon: Icons.check_rounded, onTap: () {}),
                              _IconBtn(icon: Icons.bookmark_outline_rounded, onTap: () {}),
                              _IconBtn(icon: Icons.thumb_up_outlined, onTap: () {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Text(
                                  '${(show.voteAverage * 10).toStringAsFixed(0)}% Match',
                                  style: TextStyle(
                                    color: Colors.green[400],
                                    fontWeight: FontWeight.w600,
                                    fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp,
                                  ),
                                ),
                                Text(
                                  show.firstAirDate.split('-')[0],
                                  style: TextStyle(color: Colors.white, fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp),
                                ),
                                Text(
                                  "${show.seasons.length} ${show.seasons.length > 1 ? "Seasons" : "Season"}",
                                  style: TextStyle(color: Colors.white, fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp),
                                ),
                                if (show.episodeRunTime.isNotEmpty)
                                  Text(
                                    "${show.episodeRunTime[0]} mins",
                                    style: TextStyle(color: Colors.white, fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp),
                                  ),
                                if (show.episodeRunTime.isEmpty && show.lastEpisodeToAir != null)
                                  Text(
                                    _formatRuntime(show.lastEpisodeToAir!.runtime),
                                    style: TextStyle(color: Colors.white, fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Show overview
                            ...[
                              Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 15.sp : 20.sp), 'About ${show.name}').h3,
                              const SizedBox(height: 8),
                              Text(show.overview, style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 14.sp, height: 1.5)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    child: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 15.sp), show.networks[0].name),
                                  ),
                                  Chip(
                                    child: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 15.sp), show.status),
                                  ),
                                  Chip(
                                    child: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 15.sp), show.originCountry[0]),
                                  ),
                                  Chip(
                                    child: Text(
                                      style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 15.sp),
                                      '★ ${show.voteAverage.toStringAsFixed(1)}',
                                    ),
                                  ),
                                  ...show.genres
                                      .take(3)
                                      .map(
                                        (g) => Chip(
                                          child: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 15.sp), g.name),
                                        ),
                                      ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Episodes', style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 15.sp : 20.sp)).h3,

                                _DropdownSeasons(
                                  tvShow: show,
                                  selectedSeason: show.seasons.firstWhere((s) => s.seasonNumber == episode.seasonNumber),
                                  onSeasonChanged: (season) {
                                    _seasons = TMDB.tvSeason(widget.tmdbId, season.seasonNumber);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),

                            FutureBuilder(
                              future: _seasons,
                              builder: (context, snapshot) {
                                return Column(
                                  children: [
                                    if (snapshot.hasData && snapshot.data!.episodes.isEmpty)
                                      Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 15.sp), "There are no episodes."),

                                    if (snapshot.hasData && snapshot.data!.episodes.isNotEmpty)
                                      ListView(
                                        shrinkWrap: true,
                                        controller: scrollController,
                                        children: snapshot.data!.episodes
                                            .map(
                                              (episode) => Padding(
                                                padding: EdgeInsetsGeometry.fromLTRB(0, 4, 0, 4),
                                                child: ContextMenu(
                                                  items: [
                                                    MenuButton(
                                                      trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true)),
                                                      onPressed: (context) {
                                                        AppRouter.appRouter.push(
                                                          '/streams?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}',
                                                        );
                                                      },
                                                      child: Text(
                                                        style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 15.sp),
                                                        'Select Source',
                                                      ),
                                                    ),
                                                  ],
                                                  child: GhostButton(
                                                    onPressed: () {
                                                      context.push('/player?show=${widget.tmdbId}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                                    },
                                                    child: Row(
                                                      spacing: 12,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(6),
                                                          child: CachedNetworkImage(
                                                            imageUrl:
                                                                'https://image.tmdb.org/t/p/w300${episode.stillPath ?? show.images?.backdrops.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
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
                                                              Text.rich(
                                                                TextSpan(
                                                                  children: [
                                                                    TextSpan(
                                                                      text: '${episode.seasonNumber}x${episode.episodeNumber}  ',
                                                                      style: TextStyle(
                                                                        fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 15.sp,
                                                                        fontWeight: FontWeight.w300,
                                                                      ), // "light" look
                                                                    ),
                                                                    TextSpan(
                                                                      text: episode.name,
                                                                      style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 15.sp),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Text(
                                                                episode.airDate,
                                                                style: TextStyle(
                                                                  fontSize: Device.screenType == ScreenType.desktop ? 11.sp : 13.sp,
                                                                  color: (DateTime.tryParse(episode.airDate)?.isAfter(DateTime.now()) ?? false)
                                                                      ? Colors.red.withAlpha(200)
                                                                      : Colors.white.withAlpha(200),
                                                                ),
                                                              ).light,
                                                              Text(
                                                                episode.overview,
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 11.sp : 13.sp),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return SplashScreen();
        }
      },
    );
  }
}

class _DropdownSeasons extends StatefulWidget {
  final TmdbShow tvShow;
  final SeasonSummary selectedSeason;
  final void Function(SeasonSummary) onSeasonChanged;

  const _DropdownSeasons({required this.tvShow, required this.selectedSeason, required this.onSeasonChanged});

  @override
  material.State<material.StatefulWidget> createState() => _DropdownSeasonsState();
}

class _DropdownSeasonsState extends State<_DropdownSeasons> {
  SeasonSummary? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.selectedSeason;
  }

  @override
  material.Widget build(material.BuildContext context) {
    return Select<SeasonSummary>(
      itemBuilder: (context, item) => Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 15.sp), item.name),
      popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
      onChanged: (value) {
        setState(() => _selectedSeason = value);
        widget.onSeasonChanged(value!);
      },
      value: _selectedSeason,
      placeholder: const Text('Select a season'),
      popup: SelectPopup(
        items: SelectItemList(
          children: widget.tvShow.seasons.map((s) => SelectItemButton(value: s, child: Text(s.name))).toList(),
        ),
      ).call,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.ghost(
      onPressed: () {},
      shape: ButtonShape.circle,
      density: ButtonDensity.icon,
      icon: Icon(icon, color: Colors.pink),
    );
  }
}
