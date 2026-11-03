import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/watch_history/watch_stats_snapshot.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:petal/widgets/stats/stat_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  @override
  void initState() {
    super.initState();
    BackendCache.fetchWatchHistory();
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
          child: LayoutBuilder(
            builder: (context, constraints) => MediaShelf(
              orientation: Orientation.landscape,
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
              cardHeight: 110,
              cardWidth: MediaQuery.sizeOf(context).width < 600
                  ? ((constraints.maxWidth - 8) / 2.2).clamp(120.0, 320.0).toDouble() : null,
            ),
          ),
        );
      },
    );
  }
}
