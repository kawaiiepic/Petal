import 'package:petal/api/api_cache.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:flutter/material.dart' show SliverAppBar, FlexibleSpaceBar;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/router/router.dart';
import 'package:petal/widgets/overview/cast.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieOverview extends StatefulWidget {
  final int? tmdbId;
  final String? imdbId;

  const MovieOverview({super.key, this.tmdbId, this.imdbId}) : assert(tmdbId != null || imdbId != null);

  @override
  State<MovieOverview> createState() => _MovieOverviewState();
}

class _MovieOverviewState extends State<MovieOverview> {
  Future<TmdbMovie>? _movie;

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

      if (result.movies.isEmpty) {
        return;
      }

      tmdbId = result.movies.first.id;
    }

    if (tmdbId == null || !mounted) return;

    final movie = TMDB.movie(tmdbId);

    setState(() {
      _resolvedTmdbId = tmdbId;
      _movie = movie;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _movie,
      builder: (context, snapshot) {
        final movie = snapshot.hasData ? snapshot.data! : null;
        final router = GoRouter.of(context);

        final trailer =
            movie?.videos?.results.where((v) => v.site == 'YouTube' && v.type == 'Trailer').firstOrNull ??
            movie?.videos?.results.where((v) => v.site == 'YouTube').firstOrNull;

        final cast = movie?.credits?.cast.take(12).toList();
        final director = movie?.credits?.director;
        final recommendations = movie?.recommendations?.results.take(15).toList();

        return Container(
          color: Theme.of(context).colorScheme.background,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                collapsedHeight: 300,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop
                      Image.network(
                        'https://image.tmdb.org/t/p/original${movie?.images?.backdrops.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) => SizedBox.expand(),
                      ),

                      // Bottom gradient so logo + button are readable
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.4)],
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
                            'https://image.tmdb.org/t/p/original${movie?.images?.logos.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull?.filePath}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(movie?.title ?? 'Long ass movie name.'),
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
                                    if (movie != null) {
                                      AppRouter.appRouter.push('/streams?movie=${movie.id}');
                                    }
                                  },
                                  child: const Text('Select Source'),
                                ),
                              ],
                              child: Skeleton.keep(
                                child: Button(
                                  onPressed: () => movie != null ? router.push('/player?movie=${movie.id}') : null,
                                  style: const ButtonStyle.primary().withBorderRadius(
                                    borderRadius: BorderRadius.circular(16),
                                    hoverBorderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      Icon(LucideIcons.play),
                                      Text(style: TextStyle(fontSize: Misc.bodySize), 'Play now'),
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
                                    const Icon(LucideIcons.video),
                                    Text(style: TextStyle(fontSize: Misc.bodySize), 'Trailer'),
                                  ],
                                ),
                              ),
                            ),
                            Skeleton.keep(
                              child: _IconBtn(icon: LucideIcons.check, onTap: () {}),
                            ),
                            Skeleton.keep(
                              child: _IconBtn(icon: LucideIcons.bookmark, onTap: () {}),
                            ),
                            Skeleton.keep(
                              child: _IconBtn(icon: LucideIcons.thumbsUp, onTap: () {}),
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
                            '${(movie != null ? movie.voteAverage * 10 : 80).toStringAsFixed(0)}% Match',
                            style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.w600, fontSize: Misc.labelSize),
                          ),
                          Text(
                            movie?.releaseDate.year.toString() ?? '2001',
                            style: TextStyle(color: Colors.white, fontSize: Misc.labelSize),
                          ),
                          // if (movie.episodeRunTime.isNotEmpty)
                          Text(
                            Misc.formatRuntime(movie?.runtime ?? 60),
                            style: TextStyle(color: Colors.white, fontSize: Misc.labelSize),
                          ),
                        ],
                      ),

                      if (movie?.tagline != null && movie!.tagline!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          movie.tagline!,
                          style: TextStyle(fontSize: Misc.bodySize, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],

                      const SizedBox(height: 15),

                      // movie overview
                      Text(style: TextStyle(fontSize: Misc.h3Size), 'About ${movie?.title ?? 'Movie Name'}').h3,
                      const SizedBox(height: 8),
                      Text(movie?.overview ?? 'Movie overview...', style: TextStyle(fontSize: Misc.bodySize, height: 1.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), movie?.status ?? 'Released'),
                          ),
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), movie?.status ?? 'Ongoing'),
                          ),
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), movie?.originCountry.firstOrNull ?? 'USA'),
                          ),
                          Chip(
                            child: Text(style: TextStyle(fontSize: Misc.labelSize), '★ ${movie?.voteAverage.toStringAsFixed(1) ?? 5}'),
                          ),
                          if (movie != null)
                            ...movie.genres
                                .take(3)
                                .map(
                                  (g) => Chip(
                                    child: Text(style: TextStyle(fontSize: Misc.labelSize), g.name),
                                  ),
                                ),
                          if (movie == null) ...[
                            Chip(
                              child: Text('Horror', style: TextStyle(fontSize: Misc.labelSize)),
                            ),
                            Chip(
                              child: Text('Comedy', style: TextStyle(fontSize: Misc.labelSize)),
                            ),
                          ],
                        ],
                      ),

                      if (director != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Directed by $director',
                          style: TextStyle(fontSize: Misc.bodySize, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],

                      const SizedBox(height: 20),

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
                          itemBuilder: (context, i) => CastCard(member: cast != null ? cast[i] : null),
                        ),
                      ),

                      // Recommendations
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
                          itemBuilder: (context, i) => _MovieRecommendationCard(movie: recommendations?[i]),
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

// NOTE: assumed a `Recommendedmovie`-shaped item with id/name/posterPath/voteAverage,
// mirroring TmdbMovie's `RecommendedMovie` but with `name` instead of `title` (TMDB's
// TV convention). Swap the type/field below if your model names these differently.
class _MovieRecommendationCard extends StatelessWidget {
  final RecommendedMovie? movie;

  const _MovieRecommendationCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => movie != null ? context.push('/movie?tmdb=${movie!.id}') : null,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie?.posterPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w342${movie?.posterPath}',
                      width: 110,
                      height: 155,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _PosterFallback(),
                    )
                  : _PosterFallback(),
            ),
            const SizedBox(height: 6),
            Text(
              movie?.title ?? 'Movie Name...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text('★ ${movie?.voteAverage.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
              Text('${movie?.releaseDate?.year.toString()}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)))
            ],),
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
      child: Icon(LucideIcons.ticket, color: Colors.white.withValues(alpha: 0.38)),
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
      child: Icon(LucideIcons.tv, color: Colors.white.withValues(alpha: 0.38)),
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
