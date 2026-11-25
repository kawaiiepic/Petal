import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/api/stream_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
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
  String? _selectedAddon;

  String _addonName(StreamItem stream) {
    final name = stream.addon.manifest?['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    final host = Uri.tryParse(stream.addon.baseUrl)?.host;
    return host != null && host.isNotEmpty ? host : 'Addon';
  }

  Future<void> _selectAddon(Map<String, String> addons, String? current) async {
    var changed = false;
    String? selection = current;
    await glass.showGlassActionSheet<void>(
      context: context,
      title: 'Filter by addon',
      actions: [
        glass.GlassActionSheetAction(
          label: 'All addons',
          icon: current == null ? const Icon(LucideIcons.check) : null,
          onPressed: () { selection = null; changed = true; },
        ),
        for (final addon in addons.entries)
          glass.GlassActionSheetAction(
            label: addon.value,
            icon: current == addon.key ? const Icon(LucideIcons.check) : null,
            onPressed: () { selection = addon.key; changed = true; },
          ),
      ],
    );
    if (mounted && changed) setState(() => _selectedAddon = selection);
  }

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
      _selectedAddon = null;
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
    final episodeLabel = widget.episode == null ? null :
      'S${widget.episode!.seasonNumber} · E${widget.episode!.episodeNumber}';
    return FutureBuilder(
      future: _metadata,
      builder: (context, metadata) {
        final data = metadata.data;
        return FutureBuilder<List<StreamItem>>(
          future: _streams,
          builder: (context, snapshot) {
            final allStreams = snapshot.data ?? const <StreamItem>[];
            final addons = <String, String>{
              for (final stream in allStreams) stream.addon.id: _addonName(stream),
            };
            final selected = addons.containsKey(_selectedAddon) ? _selectedAddon : null;
            final streams = selected == null ? allStreams : allStreams
                .where((stream) => stream.addon.id == selected).toList();
            final loading = snapshot.connectionState != ConnectionState.done;
            return CustomScrollView(
              shrinkWrap: true,
              primary: false,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                          Row(
                            children: [
                              Expanded(child: Text(
                                '${streams.length}${selected != null ? ' of ${allStreams.length}' : ''} ${allStreams.length == 1 ? 'source' : 'sources'} available',
                                style: TextStyle(color: colors.mutedForeground, fontSize: 13))),
                              if (addons.length > 1)
                                Flexible(child: PetalButton.ghost(
                                  onPressed: () => _selectAddon(addons, selected),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(LucideIcons.filter, size: 15, color: colors.foreground),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(selected == null ? 'All addons' : addons[selected]!,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: colors.foreground, fontSize: 13))),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.chevronDown, size: 14, color: colors.foreground),
                                  ]),
                                )),
                            ],
                          ),
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
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
        );
      },
    );
  }
}
