import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/api/stream_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:petal/widgets/streams/stream_tile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StreamsPage extends StatefulWidget {
  final int? showId;
  final int? movieId;
  final Episode? episode;
  final bool download;

  const StreamsPage({super.key, this.showId, this.movieId, this.episode,
    this.download = false});

  @override
  State<StreamsPage> createState() => _StreamsPageState();
}

class _StreamsPageState extends State<StreamsPage> {
  late Future<({String title, String? subtitle, String? artwork, String? imdbId})> _metadata;
  late Future<List<StreamItem>> _streams;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant StreamsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId || oldWidget.movieId != widget.movieId ||
        oldWidget.episode?.seasonNumber != widget.episode?.seasonNumber ||
        oldWidget.episode?.episodeNumber != widget.episode?.episodeNumber) {
      _reload();
    }
  }

  void _reload() {
    final showId = widget.showId, movieId = widget.movieId, episode = widget.episode;
    _metadata = _loadMetadata(showId, movieId, episode);
    _streams = _metadata.then((data) {
      if (data.imdbId == null || data.imdbId!.isEmpty) {
        throw StateError('No IMDb identifier available');
      }
      return StreamApi.fetchStreams(data.imdbId!, episode);
    });
  }

  Future<({String title, String? subtitle, String? artwork, String? imdbId})>
      _loadMetadata(int? showId, int? movieId, Episode? episode) async {
    if (showId != null && episode != null) {
      final details = await Future.wait([
        TMDB.tvShow(showId),
        TMDB.tvEpisode(showId, episode.seasonNumber, episode.episodeNumber),
      ]);
      final show = details[0] as TmdbShow;
      final ep = details[1] as TmdbEpisode;
      return (title: show.name, subtitle: ep.name,
        artwork: ep.stillUrl ?? show.backdropUrl, imdbId: show.imdbId);
    }
    if (movieId == null) throw StateError('Missing media identifier');
    final TmdbMovie movie = await TMDB.movie(movieId);
    return (title: movie.title, subtitle: null,
      artwork: movie.backdropPath == null ? null :
        'https://image.tmdb.org/t/p/w780${movie.backdropPath}', imdbId: movie.imdbId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottom = TvLayout.isCompact(context) && MediaQuery.viewInsetsOf(context).bottom == 0
        ? MediaQuery.viewPaddingOf(context).bottom + IosNavigationDock.clearance : 0.0;
    final episodeLabel = widget.episode == null ? null :
      'S${widget.episode!.seasonNumber} · E${widget.episode!.episodeNumber}';
    return FutureBuilder(
      future: _metadata,
      builder: (context, metadata) {
        final data = metadata.data;
        return FutureBuilder<List<StreamItem>>(
          future: _streams,
          builder: (context, snapshot) {
            final streams = snapshot.data ?? const <StreamItem>[];
            final loading = snapshot.connectionState != ConnectionState.done;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.download ? 'Download source' : 'Select source',
                          style: TextStyle(fontSize: AppTypography.h3Size, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(width: 112, height: 63,
                                child: MediaArtwork(imageUrl: data?.artwork,
                                  isLoading: !metadata.hasData && !metadata.hasError)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data?.title ?? 'Loading title',
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                if (episodeLabel != null)
                                  Text([episodeLabel, if (data?.subtitle?.isNotEmpty == true) data!.subtitle!].join(' · '),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                              ],
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!loading && !snapshot.hasError)
                          Text('${streams.length} ${streams.length == 1 ? 'source' : 'sources'} available',
                            style: TextStyle(color: colors.mutedForeground, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                if (loading)
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(32), child: Center(child: PetalActivityIndicator())))
                else if (snapshot.hasError || streams.isEmpty)
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(LucideIcons.server, color: colors.mutedForeground, size: 28),
                      const SizedBox(height: 12),
                      Text(snapshot.hasError ? 'Could not load sources' : 'No sources found'),
                      const SizedBox(height: 12),
                      PetalButton.secondary(onPressed: () => setState(_reload),
                        child: const Text('Try again')),
                    ]),
                  ))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: StreamTile(
                          stream: streams[index], tmdbId: widget.showId ?? widget.movieId!,
                          episode: widget.episode, download: widget.download,
                          mediaTitle: data?.title, episodeTitle: data?.subtitle,
                          title: episodeLabel ?? data?.title ?? streams[index].title,
                        ),
                      ),
                      childCount: streams.length,
                    )),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: bottom + 24)),
              ],
            );
          },
        );
      },
    );
  }
}
