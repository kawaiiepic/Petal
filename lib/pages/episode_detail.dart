import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/router/router.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EpisodeDetailPage extends StatefulWidget {
  final int tmdbId;
  final int season;
  final int episode;

  const EpisodeDetailPage({super.key, required this.tmdbId, required this.season, required this.episode});

  @override
  State<EpisodeDetailPage> createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> {
  late final Future<List<dynamic>> _future = Future.wait([
    TMDB.tvShow(widget.tmdbId),
    TMDB.tvEpisode(widget.tmdbId, widget.season, widget.episode),
  ]);

  String _date(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _runtime(int minutes) {
    if (minutes <= 0) return '';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        final show = snapshot.hasData ? snapshot.data![0] as TmdbShow : null;
        final episode = snapshot.hasData ? snapshot.data![1] as TmdbEpisode : null;
        final still = episode?.stillPath;
        final backdrop = show?.backdropPath;
        final imagePath = (still != null && still.isNotEmpty) ? still : backdrop;
        final guest = episode?.guestStars.take(12).toList() ?? const [];

        return Container(
          color: Theme.of(context).colorScheme.background,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imagePath != null && imagePath.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imagePath.startsWith('http') ? imagePath : 'https://image.tmdb.org/t/p/original$imagePath',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorWidget: (context, url, error) => const SizedBox.expand(),
                        )
                      else
                        const SizedBox.expand(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Theme.of(context).colorScheme.background, Colors.black.withValues(alpha: 0.15)],
                          ),
                        ),
                      ),
                      AppBar(leading: const [BackButton()], surfaceBlur: 0, surfaceOpacity: 0, alignment: Alignment.topLeft),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(show?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: Misc.smallSize, color: Colors.white.withValues(alpha: 0.75))),
                            Text(
                              episode?.name.isNotEmpty == true ? episode!.name : 'Episode ${widget.episode}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: Misc.h3Size, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              [
                                'S${widget.season} \u00b7 E${widget.episode}',
                                if (episode != null) _runtime(episode.runtime),
                                if (episode?.airDate != null) _date(episode!.airDate),
                              ].where((part) => part.isNotEmpty).join('  \u00b7  '),
                              style: TextStyle(fontSize: Misc.smallSize, color: Colors.white.withValues(alpha: 0.7)),
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Button(
                            onPressed: snapshot.hasData
                                ? () => context.push('/player?media=${widget.tmdbId}&s=${widget.season}&e=${widget.episode}')
                                : null,
                            style: const ButtonStyle.primary().withBorderRadius(borderRadius: BorderRadius.circular(16), hoverBorderRadius: BorderRadius.circular(16)),
                            child: const Row(spacing: 8, children: [Icon(LucideIcons.play), Text('Play')]),
                          ),
                          Button(
                            onPressed: snapshot.hasData
                                ? () => AppRouter.appRouter.push('/streams?show=${widget.tmdbId}&s=${widget.season}&e=${widget.episode}')
                                : null,
                            style: const ButtonStyle.outline().withBorderRadius(borderRadius: BorderRadius.circular(16), hoverBorderRadius: BorderRadius.circular(16)),
                            child: const Row(spacing: 8, children: [Icon(LucideIcons.server), Text('Source')]),
                          ),
                          Button(
                            onPressed: () => context.push('/series?tmdb=${widget.tmdbId}'),
                            style: const ButtonStyle.ghost().withBorderRadius(borderRadius: BorderRadius.circular(16), hoverBorderRadius: BorderRadius.circular(16)),
                            child: const Text('Show page'),
                          ),
                        ],
                      ),
                      if ((episode?.overview ?? '').isNotEmpty)
                        Text(episode!.overview, style: TextStyle(fontSize: Misc.bodySize, height: 1.4))
                      else if (!snapshot.hasData)
                        Text('Loading episode\u2026', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))
                      else
                        Text('No synopsis for this episode.', style: TextStyle(color: Colors.white.withValues(alpha: 0.55))),
                      if (guest.isNotEmpty) ...[
                        Text('Guest stars', style: TextStyle(fontSize: Misc.h3Size, fontWeight: FontWeight.w600)),
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: guest.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final person = guest[index];
                              return GestureDetector(
                                onTap: () => context.push('/person/${person.id}'),
                                child: SizedBox(
                                  width: 96,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: person.profilePath == null
                                            ? Container(width: 96, height: 96, color: Colors.white.withValues(alpha: 0.08), child: const Icon(LucideIcons.user))
                                            : CachedNetworkImage(
                                                imageUrl: 'https://image.tmdb.org/t/p/w185${person.profilePath}',
                                                width: 96,
                                                height: 96,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text(person.character, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
