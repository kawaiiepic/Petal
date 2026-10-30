import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/watch_history/watch_stats_snapshot.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:petal/widgets/stats/stat_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    BackendCache.fetchWatchHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.watchHistory,
      builder: (context, history, _) {
        if (history.isEmpty) return const SizedBox.shrink();
        final stats = WatchStatsSnapshot.fromHistory(history);
        final cards = [
          StatCard(
            icon: LucideIcons.flame,
            value: '${stats.streak}',
            label: stats.streak == 1 ? 'day streak' : 'day streak',
          ),
          StatCard(
            icon: LucideIcons.tv,
            value: '${stats.showsThisMonth}',
            label: 'shows this month',
          ),
          StatCard(
            icon: LucideIcons.clapperboard,
            value: '${stats.moviesThisMonth}',
            label: 'movies this month',
          ),
          StatCard(
            icon: LucideIcons.listVideo,
            value: stats.episodesPerDay.toStringAsFixed(1),
            label: 'eps / day',
          ),
          StatCard(
            icon: LucideIcons.play,
            value: '${stats.plays}',
            label: 'all-time plays',
          ),
        ];
        return HomeSection(
          title: 'Stats',
          child: SizedBox(
            height: 14.h,
            child: ScrollableWidget(
              controller: _controller,
              offset: 0,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: cards.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: SizedBox(width: 38.w, child: cards[index]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
