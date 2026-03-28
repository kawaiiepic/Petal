import 'dart:ui';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/models/custom_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EpisodeOverview extends StatefulWidget {
  final int tmdbId;
  // final TmdbShow show;

  const EpisodeOverview({super.key, required this.tmdbId});

  @override
  State<EpisodeOverview> createState() => _EpisodeOverviewState();
}

class _EpisodeOverviewState extends State<EpisodeOverview> {
  int _selectedSeason = 1;
  Episode episode = Episode(seasonNumber: 1, episodeNumber: 1);

  @override
  void initState() {
    super.initState();
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
      future: TMDB.tvShow(widget.tmdbId),
      builder: (context, showSnapshot) {
        if (showSnapshot.hasData && !showSnapshot.hasError) {
          final show = showSnapshot.data!;

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.transparent, // ← background here
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 500,
                        pinned: true,
                        forceMaterialTransparency: true,
                        backgroundColor: Colors.pink,
                        flexibleSpace: FlexibleSpaceBar(
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
                                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                    stops: const [0.0, 0.5],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Theme.of(context).scaffoldBackgroundColor,
                                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.3, 0.7],
                                  ),
                                ),
                              ),

                              // Logo — bottom left
                              Positioned(
                                bottom: 80,
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
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/player?show=${show.id}&s=${episode.seasonNumber}&e=${episode.episodeNumber}'),
                                      icon: const Icon(Icons.play_arrow_rounded),
                                      label: Text('Play now S${episode.seasonNumber}:E${episode.episodeNumber}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                      ),
                                    ),
                                    _IconBtn(icon: Icons.check_rounded, onTap: () {}),
                                    _IconBtn(icon: Icons.bookmark_outline_rounded, onTap: () {}),
                                    _IconBtn(icon: Icons.thumb_up_outlined, onTap: () {}),
                                  ],
                                ),
                              ),

                              Positioned(
                                bottom: 0, // ← negative value makes it bleed into content below
                                left: 0,
                                right: 0,
                                height: 10,
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)],
                                        ),
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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRect(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Image.network(
                                    'https://image.tmdb.org/t/p/original${show.images?.backdrops.where((l) => l.iso6391 == null || l.iso6391 == 'en').firstOrNull!.filePath}',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),

                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, // ← swapped
                                    end: Alignment.bottomCenter, // ← swapped
                                    colors: [
                                      Colors.black, // solid at top
                                      Colors.black.withOpacity(0.9), // semi at middle
                                      Colors.black.withOpacity(0.8),
                                    ],
                                    stops: const [0.0, 0.3, 0.7],
                                  ),
                                ),
                              ),
                            ),

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
                                      Text(show.firstAirDate.split('-')[0], style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      Text(
                                        "${show.seasons.length} ${show.seasons.length > 1 ? "Seasons" : "Season"}",
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      if (show.episodeRunTime.isNotEmpty)
                                        Text(show.episodeRunTime[0].toString(), style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      if (show.episodeRunTime.isEmpty && show.lastEpisodeToAir != null)
                                        Text(_formatRuntime(show.lastEpisodeToAir!.runtime), style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Show overview
                                  ...[
                                    Text('About ${show.name}', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Text(show.overview, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                                    const SizedBox(height: 8),
                                    // Show meta
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _Chip(show.networks[0].name),
                                        _Chip(show.status),
                                        // if (show.certification != null) _Chip(show.certification!),
                                        _Chip('★ ${show.voteAverage.toStringAsFixed(1)}'),
                                        ...show.genres.take(3).map((g) => _Chip(g.name)),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  const SizedBox(height: 24),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(40)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Episodes', style: Theme.of(context).textTheme.titleMedium),
                                        ],
                                      ),

                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white24),
                                          borderRadius: BorderRadius.circular(40),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              primaryColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                            ),
                                            child: DropdownButton<int>(
                                              value: _selectedSeason,
                                              isDense: true,
                                              borderRadius: BorderRadius.circular(8),
                                              focusColor: Colors.transparent,
                                              dropdownColor: Colors.transparent,
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                              items: show.mainSeasons.map((s) {
                                                return DropdownMenuItem(value: s.seasonNumber, child: Text('Season ${s.seasonNumber}'));
                                              }).toList(),
                                              onChanged: (val) {
                                                setState(() => _selectedSeason = val!);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('Episodes', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // SliverPadding(
                      //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      //   sliver: SliverList(
                      //     delegate: SliverChildListDelegate([
                      //       Row(
                      //         spacing: 8,
                      //         children: [
                      //           Text(
                      //             '${(show.voteAverage * 10).toStringAsFixed(0)}% Match',
                      //             style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.w600, fontSize: 13),
                      //           ),
                      //           Text(show.firstAirDate.split('-')[0], style: TextStyle(color: Colors.white70, fontSize: 13)),
                      //           Text(
                      //             "${show.seasons.length} ${show.seasons.length > 1 ? "Seasons" : "Season"}",
                      //             style: TextStyle(color: Colors.white70, fontSize: 13),
                      //           ),
                      //           if (show.episodeRunTime.isNotEmpty)
                      //             Text(show.episodeRunTime[0].toString(), style: TextStyle(color: Colors.white70, fontSize: 13)),
                      //           if (show.episodeRunTime.isEmpty && show.lastEpisodeToAir != null)
                      //             Text(_formatRuntime(show.lastEpisodeToAir!.runtime), style: TextStyle(color: Colors.white70, fontSize: 13)),
                      //         ],
                      //       ),
                      //       const SizedBox(height: 20),

                      //       // Show overview
                      //       ...[
                      //         Text('About ${show.name}', style: Theme.of(context).textTheme.titleMedium),
                      //         const SizedBox(height: 8),
                      //         Text(show.overview, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                      //         const SizedBox(height: 8),
                      //         // Show meta
                      //         Wrap(
                      //           spacing: 8,
                      //           runSpacing: 8,
                      //           children: [
                      //             _Chip(show.networks[0].name),
                      //             _Chip(show.status),
                      //             // if (show.certification != null) _Chip(show.certification!),
                      //             _Chip('★ ${show.voteAverage.toStringAsFixed(1)}'),
                      //             ...show.genres.take(3).map((g) => _Chip(g.name)),
                      //           ],
                      //         ),
                      //         const SizedBox(height: 24),
                      //       ],

                      //       const SizedBox(height: 24),

                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //         children: [
                      //           Row(
                      //             children: [
                      //               Container(
                      //                 width: 4,
                      //                 height: 20,
                      //                 decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(40)),
                      //               ),
                      //               const SizedBox(width: 8),
                      //               Text('Episodes', style: Theme.of(context).textTheme.titleMedium),
                      //             ],
                      //           ),

                      //           Container(
                      //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      //             decoration: BoxDecoration(
                      //               border: Border.all(color: Colors.white24),
                      //               borderRadius: BorderRadius.circular(40),
                      //             ),
                      //             child: DropdownButtonHideUnderline(
                      //               child: Theme(
                      //                 data: Theme.of(context).copyWith(
                      //                   primaryColor: Colors.transparent,
                      //                   hoverColor: Colors.transparent,
                      //                   highlightColor: Colors.transparent,
                      //                   splashColor: Colors.transparent,
                      //                 ),
                      //                 child: DropdownButton<int>(
                      //                   value: _selectedSeason,
                      //                   isDense: true,
                      //                   borderRadius: BorderRadius.circular(8),
                      //                   focusColor: Colors.transparent,
                      //                   dropdownColor: Colors.transparent,
                      //                   icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      //                   items: show.mainSeasons.map((s) {
                      //                     return DropdownMenuItem(value: s.seasonNumber, child: Text('Season ${s.seasonNumber}'));
                      //                   }).toList(),
                      //                   onChanged: (val) {
                      //                     setState(() => _selectedSeason = val!);
                      //                   },
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //       Text('Episodes', style: Theme.of(context).textTheme.titleMedium),
                      //       const SizedBox(height: 8),
                      //     ]),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white.withOpacity(0.05),
              side: BorderSide(color: Colors.white.withAlpha(50), width: 0.2),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
