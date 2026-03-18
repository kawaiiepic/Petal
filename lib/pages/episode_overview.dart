import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/stremio/stremio_episode.dart';
import 'package:blssmpetal/pages/streams.dart';
import 'package:flutter/material.dart';

class EpisodeOverview extends StatefulWidget {
  final TraktWatchedShowWithProgress item;
  final TraktEpisode? selectedEpisode;

  const EpisodeOverview({super.key, required this.item, required this.selectedEpisode});

  @override
  State<EpisodeOverview> createState() => _EpisodeOverviewState();
}

class _EpisodeOverviewState extends State<EpisodeOverview> {
  late Map<int, bool> _expandedSeasons;

  @override
  void initState() {
    super.initState();
    final currentSeason = widget.selectedEpisode?.season ?? widget.item.showProgress.nextEpisode?.season ?? 1;
    _expandedSeasons = {for (final s in widget.item.showProgress.seasons) s.number: s.number == currentSeason};
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

  // find watched info from progress seasons
  SeasonEpisode? _watchedEp(int seasonNum, int epNum) {
    try {
      final season = widget.item.showProgress.seasons.firstWhere((s) => s.number == seasonNum);
      return season.episodes.firstWhere((e) => e.number == epNum && e.completed!);
    } on StateError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.selectedEpisode ?? widget.item.showProgress.nextEpisode!;
    final show = widget.item.show ?? widget.item.watchedShow!.show;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder(
                    future: TMDB.still(show.ids.tmdb.toString(), next.season, next.number),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.black.withOpacity(0.4), Colors.transparent]),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Theme.of(context).scaffoldBackgroundColor, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // Show title
                Text(show.title, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),

                // Episode title
                Text(next.title ?? 'Episode ${next.number}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),

                // Meta row
                Wrap(
                  spacing: 12,
                  children: [
                    Text('S${next.season} · E${next.number}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    if (next.runtime != null)
                      Text(_formatRuntime(next.runtime), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    if (next.rating != null && next.rating! > 0)
                      Text('★ ${next.rating!.toStringAsFixed(1)}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    if (next.firstAired != null)
                      Text(
                        DateTime.parse(next.firstAired!).year.toString(),
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Play + action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final catalogItem = await StreamApi.fetchCatalogItemById(show.ids.imdb.toString(), "series");
                            if (catalogItem != null && context.mounted) {
                              final sEpisode = StremioEpisode(
                                season: next.season,
                                episode: next.number,
                                title: next.title ?? '',
                                overview: next.overview ?? '',
                                thumbnail: next.images.screenshot[0],
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StreamsPage(item: catalogItem, episode: sEpisode, traktShow: widget.item.watchedShow),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('Play', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(icon: Icons.check_rounded, onTap: () {}),
                    const SizedBox(width: 4),
                    _IconBtn(icon: Icons.bookmark_outline_rounded, onTap: () {}),
                    const SizedBox(width: 4),
                    _IconBtn(icon: Icons.thumb_up_outlined, onTap: () {}),
                  ],
                ),

                const SizedBox(height: 24),

                // Episode overview
                if (next.overview != null && next.overview!.isNotEmpty) ...[
                  Text('Episode overview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(next.overview!, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 24),
                ],

                // Show overview
                if (show.overview != null) ...[
                  Text('About ${show.title}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(show.overview!, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 8),
                  // Show meta
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (show.network != null) _Chip(show.network!),
                      if (show.status != null) _Chip(show.status!),
                      if (show.certification != null) _Chip(show.certification!),
                      if (show.runtime != null) _Chip('${show.runtime}m'),
                      if (show.rating != null) _Chip('★ ${show.rating!.toStringAsFixed(1)}'),
                      ...?show.genres?.take(3).map((g) => _Chip(g)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Progress
                Text('Progress', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.item.showProgress.completed} of ${widget.item.showProgress.aired} episodes watched',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${((widget.item.showProgress.completed / widget.item.showProgress.aired.clamp(1, 9999)) * 100).round()}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: widget.item.showProgress.aired > 0 ? widget.item.showProgress.completed / widget.item.showProgress.aired : 0,
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 24),

                // Episodes
                Text('Episodes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                Column(
                  children: widget.item.seasons.map((season) {
                    if (season.episodes.isEmpty) return const SizedBox();
                    final isExpanded = _expandedSeasons[season.number] ?? false;
                    final progressSeason = widget.item.showProgress.seasons.where((s) => s.number == season.number).firstOrNull;
                    final watchedCount = progressSeason?.completed ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Season header
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() => _expandedSeasons[season.number] = !isExpanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(season.title ?? 'Season ${season.number}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      if (season.firstAired != null)
                                        Text(
                                          DateTime.parse(season.firstAired!).year.toString(),
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$watchedCount/${season.airedEpisodes ?? season.episodes.length}',
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                        AnimatedCrossFade(
                          firstChild: Column(
                            children: season.episodes.map((ep) {
                              final watchedEp = _watchedEp(season.number, ep.number);
                              final isWatched = watchedEp != null;
                              final isNext = ep.number == next.number && season.number == next.season;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                leading: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          width: 100,
                                          height: 56,
                                          child: FutureBuilder(
                                            future: TMDB.still(show.ids.tmdb.toString(), season.number, ep.number),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return ColorFiltered(
                                                  colorFilter: isWatched
                                                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                                      : const ColorFilter.mode(Colors.black45, BlendMode.darken),
                                                  child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                                                );
                                              } else {
                                                return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      if (isNext)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Icon(Icons.play_circle_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                        ),
                                      if (!isNext && isWatched)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Icon(Icons.check_circle_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                        ),
                                    ],
                                  ),
                                ),
                                title: Text(
                                  'E${ep.number}  ·  ${ep.title ?? 'Episode ${ep.number}'}${isNext ? '  · Up next' : ''}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isNext ? Theme.of(context).colorScheme.primary : null),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (ep.overview != null && ep.overview!.isNotEmpty)
                                      Text(
                                        ep.overview!,
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (ep.runtime != null)
                                          Text(
                                            _formatRuntime(ep.runtime),
                                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                        if (ep.runtime != null && ep.rating != null && ep.rating! > 0)
                                          Text('  ·  ', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                        if (ep.rating != null && ep.rating! > 0)
                                          Text(
                                            '★ ${ep.rating!.toStringAsFixed(1)}',
                                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                        if (ep.firstAired != null) ...[
                                          if (ep.runtime != null || (ep.rating != null && ep.rating! > 0))
                                            Text('  ·  ', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                          Builder(
                                            builder: (context) {
                                              final d = DateTime.parse(ep.firstAired!).toLocal();
                                              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                              final formatted = '${months[d.month - 1]} ${d.day}, ${d.year}';
                                              final isUnreleased = d.isAfter(DateTime.now());
                                              return Text(
                                                formatted,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isUnreleased ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                        if (isWatched && watchedEp?.lastWatchedAt != null) ...[
                                          Text('  ·  ', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                          Text(
                                            'Watched ${_formatDate(watchedEp!.lastWatchedAt!)}',
                                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EpisodeOverview(item: widget.item, selectedEpisode: ep),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                          secondChild: const SizedBox(),
                          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 200),
                        ),

                        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
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
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
