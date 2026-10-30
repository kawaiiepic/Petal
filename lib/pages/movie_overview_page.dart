import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/router/app_router.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:petal/utils/media_formatting.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/overview/cast_card.dart';
import 'package:petal/widgets/overview/movie_recommendation_card.dart';
import 'package:petal/widgets/overview/overview_hero_actions.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieOverviewPage extends StatefulWidget {
  final int? tmdbId;
  final String? imdbId;

  const MovieOverviewPage({super.key, this.tmdbId, this.imdbId})
    : assert(tmdbId != null || imdbId != null);

  @override
  State<MovieOverviewPage> createState() => _MovieOverviewPageState();
}

class _MovieOverviewPageState extends State<MovieOverviewPage> {
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
            movie?.videos?.results
                .where((v) => v.site == 'YouTube' && v.type == 'Trailer')
                .firstOrNull ??
            movie?.videos?.results
                .where((v) => v.site == 'YouTube')
                .firstOrNull;

        final cast = movie?.credits?.cast.take(12).toList();
        final director = movie?.credits?.director;
        final recommendations = movie?.recommendations?.results
            .take(15)
            .toList();

        return Container(
          color: Theme.of(context).colorScheme.background,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://image.tmdb.org/t/p/original${(movie?.images!.backdrops.where((l) => l.iso6391 == null).toList()?..shuffle())?.first.filePath}',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            SizedBox.expand(),
                      ),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: AppBar(
                            leading: [BackButton()],
                            surfaceBlur: 0,
                            surfaceOpacity: 0.5,
                            alignment: Alignment.topLeft,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 100,
                        left: 24,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                            maxHeight: 80,
                          ),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/original${movie?.images?.logos.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull?.filePath}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Text(movie?.title ?? 'Long ass show name.'),
                          ),
                        ),
                      ),
                      OverviewHeroActions(
                        mediaType: MediaType.movie,
                        tmdbId: _resolvedTmdbId,
                        title: movie?.title,
                        onTrailer: trailer != null
                            ? () => launchUrl(Uri.parse(trailer.youtubeUrl))
                            : null,
                        play: ContextMenu(
                          items: [
                            MenuButton(
                              trailing: const MenuShortcut(
                                activator: SingleActivator(
                                  LogicalKeyboardKey.bracketLeft,
                                  control: true,
                                ),
                              ),
                              onPressed: (_) {
                                if (movie != null) {
                                  AppRouter.appRouter.push(
                                    '/streams?movie=${movie.id}',
                                  );
                                }
                              },
                              child: const Text('Select Source'),
                            ),
                          ],
                          child: Skeleton.keep(
                            child: Button(
                              onPressed: () => movie != null
                                  ? router.push('/player?media=${movie.id}')
                                  : null,
                              style: const ButtonStyle.primary()
                                  .withBorderRadius(
                                    borderRadius: BorderRadius.circular(16),
                                    hoverBorderRadius: BorderRadius.circular(
                                      16,
                                    ),
                                  ),
                              child: Row(
                                spacing: 8,
                                children: [
                                  const Icon(LucideIcons.play),
                                  Text(
                                    style: TextStyle(
                                      fontSize: AppTypography.bodySize,
                                    ),
                                    'Play',
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                            style: TextStyle(
                              color: Colors.green[400],
                              fontWeight: FontWeight.w600,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                          Text(
                            movie?.releaseDate.year.toString() ?? '2001',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                          Text(
                            MediaFormatting.formatRuntime(movie?.runtime ?? 60),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                        ],
                      ),
                      if (movie?.tagline != null &&
                          movie!.tagline!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          movie.tagline!,
                          style: TextStyle(
                            fontSize: AppTypography.bodySize,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      Text(
                        style: TextStyle(fontSize: AppTypography.h3Size),
                        'About ${movie?.title ?? 'Movie Name'}',
                      ).h3,
                      const SizedBox(height: 8),
                      Text(
                        movie?.overview ?? 'Movie overview...',
                        style: TextStyle(
                          fontSize: AppTypography.bodySize,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              movie?.status ?? 'Released',
                            ),
                          ),
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              movie?.status ?? 'Ongoing',
                            ),
                          ),
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              movie?.originCountry.firstOrNull ?? 'USA',
                            ),
                          ),
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              '★ ${movie?.voteAverage.toStringAsFixed(1) ?? 5}',
                            ),
                          ),
                          if (movie != null)
                            ...movie.genres
                                .take(3)
                                .map(
                                  (g) => Chip(
                                    child: Text(
                                      style: TextStyle(
                                        fontSize: AppTypography.labelSize,
                                      ),
                                      g.name,
                                    ),
                                  ),
                                ),
                          if (movie == null) ...[
                            Chip(
                              child: Text(
                                'Horror',
                                style: TextStyle(
                                  fontSize: AppTypography.labelSize,
                                ),
                              ),
                            ),
                            Chip(
                              child: Text(
                                'Comedy',
                                style: TextStyle(
                                  fontSize: AppTypography.labelSize,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (director != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Directed by $director',
                          style: TextStyle(
                            fontSize: AppTypography.bodySize,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Skeleton.keep(
                        child: Text(
                          style: TextStyle(fontSize: AppTypography.h4Size),
                          'Cast',
                        ).h4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cast != null ? cast.length : 3,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) =>
                              CastCard(member: cast != null ? cast[i] : null),
                        ),
                      ),
                      Skeleton.keep(
                        child: Text(
                          style: TextStyle(fontSize: AppTypography.h4Size),
                          'More Like This',
                        ).h4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations?.length ?? 10,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => MovieRecommendationCard(
                            movie: recommendations?[i],
                          ),
                        ),
                      ),
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
