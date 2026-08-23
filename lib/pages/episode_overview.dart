import 'package:flutter_js/quickjs/ffi.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/custom_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/router/router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class EpisodeOverview extends StatefulWidget {
  final int? tmdbId;
  final String? imdbId;

  const EpisodeOverview({super.key, this.tmdbId, this.imdbId}) : assert(tmdbId != null || imdbId != null);

  @override
  State<EpisodeOverview> createState() => _EpisodeOverviewState();
}

class _EpisodeOverviewState extends State<EpisodeOverview> {
  Future<TmdbShow>? _show;
  Future<TmdbSeason>? _season;

  Episode episode = Episode(seasonNumber: 1, episodeNumber: 1);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initData();
  }

  int? _resolvedTmdbId;

  Future<void> initData() async {
    int? tmdbId = widget.tmdbId;

    if (tmdbId == null && widget.imdbId != null) {
      final result = await ApiCache.getTmdbSearch(widget.imdbId!);

      if (result.tv.isEmpty) {
        return;
      }

      tmdbId = result.tv.first.id;
    }

    if (tmdbId == null || !mounted) return;

    final show = TMDB.tvShow(tmdbId);
    final season = TMDB.tvSeason(tmdbId, episode.seasonNumber);

    setState(() {
      _resolvedTmdbId = tmdbId;
      _show = show;
      _season = season;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _show,
      builder: (context, snapshot) {
        final show = snapshot.hasData ? snapshot.data! : null;
        final router = GoRouter.of(context);

        final trailer =
            show?.videos?.results.where((v) => v.site == 'YouTube' && v.type == 'Trailer').firstOrNull ??
            show?.videos?.results.where((v) => v.site == 'YouTube').firstOrNull;

        final cast = show?.credits?.cast.take(12).toList();
        final recommendations = show?.recommendations?.results.take(15).toList();

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
                        'https://image.tmdb.org/t/p/original${show?.images?.backdrops.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) => SizedBox.expand(),
                      ),

                      // Bottom gradient so logo + button are readable
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.4)],
                              stops: const [0.0, 1.0],
                            ),
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
                            'https://image.tmdb.org/t/p/original${show?.images?.logos.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull?.filePath}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(show?.name ?? 'Long ass show name.'),
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
                                    if (show != null) {
                                      AppRouter.appRouter.push('/streams?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                    }
                                  },
                                  child: const Text('Select Source'),
                                ),
                              ],
                              child: Skeleton.keep(
                                child: Button(
                                  onPressed: () =>
                                      show != null ? router.push('/player?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}') : null,
                                  style: const ButtonStyle.primary().withBorderRadius(
                                    borderRadius: BorderRadius.circular(16),
                                    hoverBorderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      Icon(Icons.play_arrow_rounded),
                                      Text(style: TextStyle(fontSize: Misc.bodySize), 'S${episode.seasonNumber}:E${episode.episodeNumber}'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Skeleton.keep(
                              child: Button(
                                onPressed: () => trailer != null ? launchUrl(Uri.parse(trailer.youtubeUrl)) : null,
                                style: const ButtonStyle.outline().withBorderRadius(
                                  borderRadius: BorderRadius.circular(16),
                                  hoverBorderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    const Icon(Icons.smart_display_outlined),
                                    Text(style: TextStyle(fontSize: Misc.bodySize), 'Trailer'),
                                  ],
                                ),
                              ),
                            ),
                            Skeleton.keep(
                              child: _IconBtn(icon: Icons.check_rounded, onTap: () {}),
                            ),
                            Skeleton.keep(
                              child: _IconBtn(icon: Icons.bookmark_outline_rounded, onTap: () {}),
                            ),
                            Skeleton.keep(
                              child: _IconBtn(icon: Icons.thumb_up_outlined, onTap: () {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Text(
                            '${(show != null ? show.voteAverage * 10 : 80).toStringAsFixed(0)}% Match',
                            style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.w600, fontSize: Misc.labelSize),
                          ),
                          Text(
                            show?.firstAirDate.split('-').firstOrNull ?? '2001',
                            style: TextStyle(color: Colors.white, fontSize: Misc.labelSize),
                          ),
                          Text(
                            "${show?.seasons.length ?? '20'} ${show == null || show.seasons.length > 1 ? "Seasons" : "Season"}",
                            style: TextStyle(color: Colors.white, fontSize: Misc.labelSize),
                          ),
                          // if (show.episodeRunTime.isNotEmpty)
                          Text(
                            "${show?.episodeRunTime.firstOrNull ?? '20'} mins",
                            style: TextStyle(color: Colors.white, fontSize: Misc.labelSize),
                          ),
                          if (show != null && show.episodeRunTime.isEmpty && show.lastEpisodeToAir != null)
                            Text(
                              Misc.formatRuntime(show.lastEpisodeToAir!.runtime),
                              style: TextStyle(color: Colors.white, fontSize: Misc.labelSize),
                            ),
                        ],
                      ),

                      if (show?.tagline != null && show!.tagline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          show.tagline,
                          style: TextStyle(fontSize: Misc.bodySize, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Show overview
                      Text(style: TextStyle(fontSize: Misc.h3Size), 'About ${show?.name ?? 'Show Name'}').h3,
                      const SizedBox(height: 8),
                      Text(show?.overview ?? 'Show overview...', style: TextStyle(fontSize: Misc.bodySize, height: 1.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), show?.networks.firstOrNull?.name ?? 'Netflix'),
                          ),
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), show?.status ?? 'Ongoing'),
                          ),
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), show?.originCountry.firstOrNull ?? 'USA'),
                          ),
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), '★ ${show?.voteAverage.toStringAsFixed(1) ?? 5}'),
                          ),
                          if (show != null)
                            ...show.genres
                                .take(3)
                                .map(
                                  (g) => Chip(
                                    child: Text(style: TextStyle(fontSize: Misc.labelSize), g.name),
                                  ),
                                ),
                          if (show == null) ...[
                            Chip(
                              child: Text('Horror', style: TextStyle(fontSize: Misc.labelSize)),
                            ),
                            Chip(
                              child: Text('Comedy', style: TextStyle(fontSize: Misc.labelSize)),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Cast row
                      // if (cast.isNotEmpty) ...[
                      Skeleton.keep(
                        child: Text(style: TextStyle(fontSize: Misc.h4Size), 'Cast').h4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cast != null ? cast.length : 3,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _CastCard(member: cast != null ? cast[i] : null),
                        ),
                      ),

                      // ],
                      Skeleton.keep(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(style: TextStyle(fontSize: Misc.h3Size), 'Episodes').h3,

                            _DropdownSeasons(
                              tvShow: show,
                              selectedSeason: show?.seasons.firstWhere((s) => s.seasonNumber == episode.seasonNumber),
                              onSeasonChanged: (season) {
                                _season = TMDB.tvSeason(_resolvedTmdbId!, season.seasonNumber);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),

                      FutureBuilder(
                        future: _season,
                        builder: (context, snapshot) {
                          return Column(
                            children: [
                              if (snapshot.hasData && snapshot.data!.episodes.isEmpty) Text(style: TextStyle(fontSize: Misc.bodySize), "There are no episodes."),

                              if (snapshot.hasData && snapshot.data!.episodes.isNotEmpty)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.episodes.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final episode = snapshot.data!.episodes[i];
                                    return ContextMenu(
                                      items: [
                                        MenuButton(
                                          trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true)),
                                          onPressed: (context) {
                                            if (show != null) {
                                              AppRouter.appRouter.push('/streams?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                            }
                                          },
                                          child: Text(style: TextStyle(fontSize: Misc.bodySize), 'Select Source'),
                                        ),
                                      ],
                                      child: GhostButton(
                                        onPressed: () {
                                          context.push('/player?show=${widget.tmdbId}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                        },
                                        child: Row(
                                          spacing: 12,
                                          children: [
                                            Skeleton.keep(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Stack(
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl: 'https://image.tmdb.org/t/p/w300${episode.stillPath}',
                                                      width: 120,
                                                      height: 68,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context, url, error) => const _EpisodeThumbFallback(),
                                                    ),
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment.bottomCenter,
                                                            end: Alignment.topCenter,
                                                            colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.1)],
                                                            stops: const [0.0, 1.0],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    ValueListenableBuilder(
                                                      valueListenable: BackendCache.continueWatching,
                                                      builder: (context, value, child) {
                                                        if (value.any((boop) {
                                                          if (boop.mediaType == "episode") {
                                                            final showItem = boop as ShowItem;
                                                            return (showItem.tmdbId == _resolvedTmdbId &&
                                                                showItem.nextEpisode?.season == episode.seasonNumber &&
                                                                showItem.nextEpisode?.episode == episode.episodeNumber);
                                                          }
                                                          return false;
                                                        })) {
                                                          return const Positioned(
                                                            top: 4,
                                                            right: 4,
                                                            left: 4,
                                                            bottom: 4,
                                                            child: Icon(Icons.play_arrow_rounded, size: 30, color: Colors.white),
                                                          );
                                                        } else {
                                                          return Container();
                                                        }
                                                      },
                                                    ),
                                                    ValueListenableBuilder(
                                                      valueListenable: BackendCache.watchHistory,
                                                      builder: (context, history, child) {
                                                        final entry = history.firstWhereOrNull(
                                                          (h) => h.tmdbId == show?.id && h.season == episode.seasonNumber && h.episode == episode.episodeNumber,
                                                        );

                                                        if (entry == null || entry.completion <= 0.0) {
                                                          return const SizedBox.shrink();
                                                        }

                                                        final isCompleted = entry.completion >= 1.0;

                                                        if (isCompleted) {
                                                          return const Positioned(
                                                            top: 4,
                                                            right: 4,
                                                            child: Icon(Icons.check_rounded, size: 20, color: Colors.white),
                                                          );
                                                        }

                                                        return Positioned(
                                                          bottom: 2,
                                                          left: 5,
                                                          right: 5,
                                                          child: LinearProgressIndicator(
                                                            value: entry.completion,
                                                            minHeight: 5,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),

                                                // ValueListenableBuilder(valueListenable: BackendCache.watchHistory, builder:(context, value, child) => Stack(children: [

                                                // ],),)
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
                                                          style: TextStyle(fontSize: Misc.bodySize, fontWeight: FontWeight.w300),
                                                        ),
                                                        TextSpan(
                                                          text: episode.name,
                                                          style: TextStyle(fontSize: Misc.bodySize),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    episode.airDate,
                                                    style: TextStyle(
                                                      fontSize: Misc.smallSize,
                                                      color: (DateTime.tryParse(episode.airDate)?.isAfter(DateTime.now()) ?? false)
                                                          ? Colors.red.withAlpha(200)
                                                          : Colors.white.withAlpha(200),
                                                    ),
                                                  ).light,
                                                  Text(
                                                    episode.overview,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: Misc.smallSize),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),

                      // Recommendations
                      // if (recommendations.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Skeleton.keep(
                        child: Text(style: TextStyle(fontSize: Misc.h4Size), 'More Like This').h4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations?.length ?? 10,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _ShowRecommendationCard(show: recommendations?[i]),
                        ),
                      ),
                      // ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).asSkeleton(snapshot: snapshot);
      },
    );
  }
}

class _DropdownSeasons extends StatefulWidget {
  final TmdbShow? tvShow;
  final SeasonSummary? selectedSeason;
  final void Function(SeasonSummary) onSeasonChanged;

  const _DropdownSeasons({required this.tvShow, required this.selectedSeason, required this.onSeasonChanged});

  @override
  State<_DropdownSeasons> createState() => _DropdownSeasonsState();
}

class _DropdownSeasonsState extends State<_DropdownSeasons> {
  SeasonSummary? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.selectedSeason;
  }

  @override
  Widget build(BuildContext context) {
    return Select<SeasonSummary>(
      itemBuilder: (context, item) => Text(style: TextStyle(fontSize: Misc.bodySize), item.name),
      popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
      onChanged: (value) {
        setState(() => _selectedSeason = value);
        widget.onSeasonChanged(value!);
      },
      value: _selectedSeason,
      placeholder: const Text('Select a season'),
      popup: SelectPopup(
        items: SelectItemList(
          children: widget.tvShow != null
              ? widget.tvShow!.seasons.map((s) => SelectItemButton(value: s, child: Text(s.name))).toList()
              : List.generate(5, (index) => SelectItemButton(value: "Queer", child: Text('Example Season'))),
        ),
      ).call,
    );
  }
}

class _CastCard extends StatelessWidget {
  final CastMember? member;

  const _CastCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => member != null ? context.push('/person/${member!.id}') : null,
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            ClipOval(
              child: member != null && member!.profilePath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w185${member!.profilePath}',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _CastFallbackAvatar(),
                    )
                  : _CastFallbackAvatar(),
            ),
            const SizedBox(height: 8),
            Text(
              member?.name ?? 'Random Name',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (member?.character != null)
              Text(
                member!.character!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CastFallbackAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.38)),
    );
  }
}

// NOTE: assumed a `RecommendedShow`-shaped item with id/name/posterPath/voteAverage,
// mirroring TmdbMovie's `RecommendedMovie` but with `name` instead of `title` (TMDB's
// TV convention). Swap the type/field below if your model names these differently.
class _ShowRecommendationCard extends StatelessWidget {
  final RecommendedShow? show;

  const _ShowRecommendationCard({required this.show});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => show != null ? context.push('/series?tmdb=${show!.id}') : null,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: show?.posterPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w342${show?.posterPath}',
                      width: 110,
                      height: 155,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _PosterFallback(),
                    )
                  : _PosterFallback(),
            ),
            const SizedBox(height: 6),
            Text(
              show?.name ?? 'Show Name...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text('★ ${show?.voteAverage.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
              Text('${show?.firstAirDate?.year.toString()}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)))
            ],)
            ,
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 155,
      color: Colors.white.withValues(alpha: 0.12),
      child: Icon(Icons.movie_outlined, color: Colors.white.withValues(alpha: 0.38)),
    );
  }
}

class _EpisodeThumbFallback extends StatelessWidget {
  const _EpisodeThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 68,
      color: Colors.white.withValues(alpha: 0.12),
      child: Icon(Icons.tv_outlined, color: Colors.white.withValues(alpha: 0.38)),
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
      onPressed: onTap,
      shape: ButtonShape.circle,
      density: ButtonDensity.icon,
      icon: Icon(icon, color: Colors.pink),
    );
  }
}
