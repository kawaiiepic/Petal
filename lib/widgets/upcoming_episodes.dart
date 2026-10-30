import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/upcoming_releases.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

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
                    child: Column(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: HoverableItem(
                            orientation: Orientation.landscape,
                            onTap: () => context.push(
                              '/episode?tmdb=${item.tmdbId}&s=${item.season}&e=${item.episode}',
                            ),
                            image: item.image == null
                                ? Avatar(
                                    initials: '',
                                    borderRadius: 12,
                                  ).asSkeleton()
                                : CachedNetworkImage(
                                    imageUrl: item.image!,
                                    fit: BoxFit.cover,
                                  ),
                            extraWidget: Positioned(
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
                                  _when(item.airDate),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Device.screenType == ScreenType.desktop
                              ? 5.h
                              : 6.h,
                          child: Column(
                            children: [
                              Text(
                                '${item.season}x${item.episode} ${item.showName}',
                                style: TextStyle(fontSize: 15.px),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.episodeName,
                                style: TextStyle(fontSize: 15.px),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
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
