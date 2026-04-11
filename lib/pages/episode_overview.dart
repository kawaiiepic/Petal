import 'dart:ui';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/tmdb/tmdb_models.dart';
import 'package:blssmpetal/models/custom_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EpisodeOverview extends StatefulWidget {
  final int tmdbId;
  // final TmdbShow show;

  const EpisodeOverview({super.key, required this.tmdbId});

  @override
  State<EpisodeOverview> createState() => _EpisodeOverviewState();
}

class _EpisodeOverviewState extends State<EpisodeOverview> {
  late Future<TmdbShow> _tvShow;
  late Future<TmdbSeason> _seasons;

  Episode episode = Episode(seasonNumber: 1, episodeNumber: 1);

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

          return Container(
            color: Theme.of(context).colorScheme.background, // Set your desired color here
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 500,
                  pinned: true,
                  backgroundColor: Colors.pink,
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
                              'https://image.tmdb.org/t/p/original${show.images?.logos.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 24,
                          left: 24,
                          child: Row(
                            spacing: 8,
                            children: [
                              Button(
                                onPressed: () => context.push('/player?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}'),
                                style: const ButtonStyle.primary().withBorderRadius(
                                  borderRadius: BorderRadius.circular(16),
                                  hoverBorderRadius: BorderRadius.circular(16),
                                ),
                                trailing: Text('Play now S${episode.seasonNumber}:E${episode.episodeNumber}'),
                                child: const Icon(Icons.play_arrow_rounded),
                              ),
                              _IconBtn(icon: Icons.check_rounded, onTap: () {}),
                              _IconBtn(icon: Icons.bookmark_outline_rounded, onTap: () {}),
                              _IconBtn(icon: Icons.thumb_up_outlined, onTap: () {}),
                            ],
                          ),
                        ),

                        // Positioned(
                        //   bottom: 0, // ← negative value makes it bleed into content below
                        //   left: 0,
                        //   right: 0,
                        //   height: 10,
                        //   child: ClipRect(
                        //     child: BackdropFilter(
                        //       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        //       child: Container(
                        //         decoration: BoxDecoration(
                        //           gradient: LinearGradient(
                        //             begin: Alignment.bottomCenter,
                        //             end: Alignment.topCenter,
                        //             colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)],
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Positioned.fill(
                      //   child: ClipRect(
                      //     child: ImageFiltered(
                      //       imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      //       child: Image.network(
                      //         'https://image.tmdb.org/t/p/original${show.images?.backdrops.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
                      //         fit: BoxFit.cover,
                      //         alignment: Alignment.bottomCenter,
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // Positioned.fill(
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       gradient: LinearGradient(
                      //         begin: Alignment.topCenter, // ← swapped
                      //         end: Alignment.bottomCenter, // ← swapped
                      //         colors: [
                      //           Colors.black, // solid at top
                      //           Colors.black.withOpacity(0.9), // semi at middle
                      //           Colors.black.withOpacity(0.8),
                      //         ],
                      //         stops: const [0.0, 0.3, 0.7],
                      //       ),
                      //     ),
                      //   ),
                      // ),
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
                                  style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(show.firstAirDate.split('-')[0], style: TextStyle(color: Colors.white, fontSize: 13)),
                                Text(
                                  "${show.seasons.length} ${show.seasons.length > 1 ? "Seasons" : "Season"}",
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                if (show.episodeRunTime.isNotEmpty)
                                  Text(show.episodeRunTime[0].toString(), style: TextStyle(color: Colors.white, fontSize: 13)),
                                if (show.episodeRunTime.isEmpty && show.lastEpisodeToAir != null)
                                  Text(_formatRuntime(show.lastEpisodeToAir!.runtime), style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Show overview
                            ...[
                              Text('About ${show.name}').h3,
                              const SizedBox(height: 8),
                              Text(show.overview, style: TextStyle(fontSize: 14, height: 1.5)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(child: Text(show.networks[0].name)),
                                  Chip(child: Text(show.status)),
                                  Chip(child: Text(show.originCountry[0])),
                                  Chip(child: Text('★ ${show.voteAverage.toStringAsFixed(1)}')),
                                  ...show.genres.take(3).map((g) => Chip(child: Text(g.name))),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Episodes', style: TextStyle(fontSize: 20)).h3,

                                _DropdownSeasons(
                                  tvShow: show,
                                  selectedSeason: episode.seasonNumber,
                                  onSeasonChanged: (season) {
                                    _seasons = TMDB.tvSeason(widget.tmdbId, season);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            FutureBuilder(
                              future: _seasons,
                              builder: (context, snapshot) {
                                return Column(
                                  children: [
                                    if (snapshot.hasData && snapshot.data!.episodes.isEmpty) Text("There is no episodes."),

                                    if (snapshot.hasData && snapshot.data!.episodes.isNotEmpty)
                                      ListView(
                                        shrinkWrap: true,
                                        children: snapshot.data!.episodes
                                            .map(
                                              (episode) => Padding(
                                                padding: EdgeInsetsGeometry.fromLTRB(0, 4, 0, 4),
                                                child: GhostButton(
                                                  onPressed: () {
                                                    context.pushReplacement(
                                                      '/player?show=${widget.tmdbId}&s=${episode.seasonNumber}&e=${episode.episodeNumber}',
                                                    );
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
                                                            Row(
                                                              spacing: 8,
                                                              children: [Text('${episode.seasonNumber}x${episode.episodeNumber}').light, Text(episode.name)],
                                                            ),
                                                            Text(
                                                              episode.airDate,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: DateTime.parse(episode.airDate).isAfter(DateTime.now())
                                                                    ? Colors.red.withAlpha(200)
                                                                    : Colors.white.withAlpha(200),
                                                              ),
                                                            ).light,
                                                            Text(
                                                              episode.overview,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(fontSize: 12),
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
          return SizedBox();
        }
      },
    );
  }
}

class _DropdownSeasons extends StatefulWidget {
  final TmdbShow tvShow;
  final int selectedSeason;
  final void Function(int) onSeasonChanged;

  const _DropdownSeasons({required this.tvShow, required this.selectedSeason, required this.onSeasonChanged});

  @override
  material.State<material.StatefulWidget> createState() => _DropdownSeasonsState();
}

class _DropdownSeasonsState extends State<_DropdownSeasons> {
  int? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.selectedSeason;
  }

  @override
  material.Widget build(material.BuildContext context) {
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
          children: widget.tvShow.seasons.map((s) => SelectItemButton(value: s.seasonNumber, child: Text(s.name))).toList(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Button.outline(
            onPressed: onTap,
            // style: OutlinedButton.styleFrom(
            //   padding: EdgeInsets.zero,
            //   backgroundColor: Colors.white.withOpacity(0.05),
            //   side: BorderSide(color: Colors.white.withAlpha(50), width: 0.2),
            // ),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
