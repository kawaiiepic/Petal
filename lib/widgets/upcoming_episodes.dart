import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class UpcomingItem {
  final int tmdbId;
  final String showName;
  final String episodeName;
  final int season;
  final int episode;
  final DateTime airDate;
  final String? image;

  const UpcomingItem({
    required this.tmdbId,
    required this.showName,
    required this.episodeName,
    required this.season,
    required this.episode,
    required this.airDate,
    this.image,
  });
}

class UpcomingEpisodes extends StatefulWidget {
  const UpcomingEpisodes({super.key});

  @override
  State<UpcomingEpisodes> createState() => _UpcomingEpisodesState();
}

class _UpcomingEpisodesState extends State<UpcomingEpisodes> {
  Future<List<UpcomingItem>>? _future;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    BackendCache.fetchWatchHistory();
    BackendCache.watchHistory.addListener(_reload);
    _future = _load();
  }

  @override
  void dispose() {
    BackendCache.watchHistory.removeListener(_reload);
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<List<UpcomingItem>> _load() async {
    final history = BackendCache.watchHistory.value;
    final ids = <int>{};
    for (final item in history) {
      if (item.mediaType == MediaType.show) ids.add(item.tmdbId);
    }
    if (ids.isEmpty) return const [];

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final cutoff = today.add(const Duration(days: 60));
    final items = <UpcomingItem>[];

    await Future.wait(
      ids.take(40).map((id) async {
        try {
          final response = await TMDB.tmdbApi('/tv/$id');
          final data = response.data as Map<String, dynamic>;
          final next = data['next_episode_to_air'] as Map<String, dynamic>?;
          if (next == null) return;
          final rawDate = next['air_date'] as String?;
          if (rawDate == null || rawDate.isEmpty) return;
          final air = DateTime.tryParse(rawDate);
          if (air == null || air.isBefore(today) || air.isAfter(cutoff)) return;
          final poster = data['poster_path'] as String?;
          final still = next['still_path'] as String?;
          items.add(
            UpcomingItem(
              tmdbId: id,
              showName: (data['name'] as String?) ?? 'Show',
              episodeName: (next['name'] as String?) ?? 'Episode',
              season: (next['season_number'] as num?)?.toInt() ?? 1,
              episode: (next['episode_number'] as num?)?.toInt() ?? 1,
              airDate: air,
              image: still != null
                  ? Api.proxyImage('https://image.tmdb.org/t/p/w500$still')
                  : poster != null
                  ? Api.proxyImage('https://image.tmdb.org/t/p/w500$poster')
                  : null,
            ),
          );
        } catch (_) {}
      }),
    );

    items.sort((a, b) => a.airDate.compareTo(b.airDate));
    return items;
  }

  String _when(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UpcomingItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <UpcomingItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Upcoming',
          child: SizedBox(
            height: 25.h,
            child: ScrollableWidget(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(2.w, 8, 2.w, 8),
                    child: SizedBox(
                      width: 42.w,
                      child: Column(
                        children: [
                          Expanded(
                            child: HoverableItem(
                              orientation: Orientation.landscape,
                              onTap: () => context.push('/series?tmdb=${item.tmdbId}'),
                              image: item.image == null
                                  ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                                  : CachedNetworkImage(imageUrl: item.image!, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${item.season}x${item.episode} ${item.showName}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${item.episodeName} · ${_when(item.airDate)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
