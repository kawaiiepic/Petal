import 'package:petal/widgets/home/home_shelf_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/upcoming_releases.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class UpcomingEpisodes extends StatefulWidget {
  const UpcomingEpisodes({super.key});

  @override
  State<UpcomingEpisodes> createState() => _UpcomingEpisodesState();
}

class _UpcomingEpisodesState extends State<UpcomingEpisodes> {
  bool _loading = true;

  Future<void> _fetch() async {
    try {
      await UpcomingReleases.fetch();
    } catch (_) {
      // Keep already loaded releases when a refresh fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetch();
    UserLibrary.watchlist.addListener(_fetch);
    BackendCache.watchHistory.addListener(_fetch);
  }

  @override
  void dispose() {
    UserLibrary.watchlist.removeListener(_fetch);
    BackendCache.watchHistory.removeListener(_fetch);
    super.dispose();
  }

  String _when(DateTime date) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == 2) return 'in 2 days';
    if (diff < 7) return 'in $diff days';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UpcomingReleases.items,
      builder: (context, all, _) {
        final seen = <String>{};
        final items = <UpcomingItem>[];
        for (final item in all) {
          if (!seen.add('${item.type.name}:${item.tmdbId}')) continue;
          items.add(item);
        }
        if (items.isEmpty && _loading) {
          return const HomeShelfSkeleton(
            title: 'Upcoming', orientation: Orientation.landscape);
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Upcoming',
          child: MediaShelf(
            orientation: Orientation.landscape,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return MediaCard(
                orientation: Orientation.landscape,
                onTap: () => context.push(
                  item.type == MediaType.movie
                      ? '/movie?tmdb=${item.tmdbId}'
                      : '/episode?tmdb=${item.tmdbId}&s=${item.season}&e=${item.episode}',
                ),
                imageUrl: item.image,
                overlay: Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE6101018),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.type == MediaType.movie ? 'Movie' : 'S${item.season} · E${item.episode}'} · ${_when(item.airDate)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                label: item.type == MediaType.movie
                    ? item.showName
                    : '${item.season}x${item.episode} ${item.showName}: ${item.episodeName}',
                target: MediaCardTarget(
                  tmdbId: item.tmdbId,
                  type: item.type,
                  season: item.type == MediaType.show ? item.season : null,
                  episode: item.type == MediaType.show ? item.episode : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
