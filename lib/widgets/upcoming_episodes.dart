import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/user_library.dart';
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

class UpcomingReleases {
  static final ValueNotifier<List<UpcomingItem>> items = ValueNotifier(const []);
  static Future<void>? _inFlight;

  static Future<void> fetch() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  static Future<void> _load() async {
    await BackendCache.fetchWatchHistory();
    final ids = <int>{};
    for (final item in BackendCache.watchHistory.value) {
      if (item.mediaType == MediaType.show) ids.add(item.tmdbId);
    }
    for (final title in UserLibrary.watchlistTitles()) {
      if (title.type == MediaType.show) ids.add(title.tmdbId);
    }
    if (ids.isEmpty) {
      items.value = const [];
      return;
    }

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final cutoff = today.add(const Duration(days: 45));
    final found = <UpcomingItem>[];

    await Future.wait(
      ids.take(30).map((id) async {
        try {
          final response = await TMDB.tmdbApi('/tv/$id');
          final data = response.data as Map<String, dynamic>;
          final next = data['next_episode_to_air'] as Map<String, dynamic>?;
          final last = data['last_episode_to_air'] as Map<String, dynamic>?;
          final seasonNumber = (next?['season_number'] as num?)?.toInt() ?? (last?['season_number'] as num?)?.toInt();
          if (seasonNumber == null) return;
          final showName = (data['name'] as String?) ?? 'Show';
          final poster = data['poster_path'] as String?;
          final seasonRes = await TMDB.tmdbApi('/tv/$id/season/$seasonNumber');
          final episodes = (seasonRes.data['episodes'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
          for (final episode in episodes) {
            final rawDate = episode['air_date'] as String?;
            if (rawDate == null || rawDate.isEmpty) continue;
            final air = DateTime.tryParse(rawDate);
            if (air == null) continue;
            final day = DateTime(air.year, air.month, air.day);
            if (day.isBefore(today) || day.isAfter(cutoff)) continue;
            final still = episode['still_path'] as String?;
            found.add(
              UpcomingItem(
                tmdbId: id,
                showName: showName,
                episodeName: (episode['name'] as String?) ?? 'Episode',
                season: (episode['season_number'] as num?)?.toInt() ?? seasonNumber,
                episode: (episode['episode_number'] as num?)?.toInt() ?? 1,
                airDate: day,
                image: still != null && still.isNotEmpty
                    ? Api.proxyImage('https://image.tmdb.org/t/p/w500$still')
                    : poster != null && poster.isNotEmpty
                    ? Api.proxyImage('https://image.tmdb.org/t/p/w500$poster')
                    : null,
              ),
            );
          }
        } catch (_) {}
      }),
    );

    found.sort((a, b) => a.airDate.compareTo(b.airDate));
    items.value = found;
  }
}

class UpcomingEpisodes extends StatefulWidget {
  const UpcomingEpisodes({super.key});

  @override
  State<UpcomingEpisodes> createState() => _UpcomingEpisodesState();
}

class _UpcomingEpisodesState extends State<UpcomingEpisodes> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    UpcomingReleases.fetch();
    UserLibrary.watchlist.addListener(UpcomingReleases.fetch);
    BackendCache.watchHistory.addListener(UpcomingReleases.fetch);
  }

  @override
  void dispose() {
    UserLibrary.watchlist.removeListener(UpcomingReleases.fetch);
    BackendCache.watchHistory.removeListener(UpcomingReleases.fetch);
    _controller.dispose();
    super.dispose();
  }

  String _when(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
        final seen = <int>{};
        final items = <UpcomingItem>[];
        for (final item in all) {
          if (!seen.add(item.tmdbId)) continue;
          items.add(item);
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Upcoming',
          child: SizedBox(
            height: 25.h,
            child: ScrollableWidget(
              controller: _controller,
              offset: -25,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(2.w, 8, 2.w, 8),
                    child: SizedBox(
                      width: 55.w,
                      child: Column(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: HoverableItem(
                              orientation: Orientation.landscape,
                              onTap: () => context.push('/episode?tmdb=${item.tmdbId}&s=${item.season}&e=${item.episode}'),
                              image: item.image == null
                                  ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                                  : CachedNetworkImage(imageUrl: item.image!, fit: BoxFit.cover),
                              extraWidget: Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xE6101018), borderRadius: BorderRadius.circular(8)),
                                  child: Text(_when(item.airDate), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
                            child: Column(
                              children: [
                                Text('${item.season}x${item.episode} ${item.showName}', style: TextStyle(fontSize: 15.px), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(item.episodeName, style: TextStyle(fontSize: 15.px), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
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
