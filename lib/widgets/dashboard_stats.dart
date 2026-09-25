import 'package:go_router/go_router.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/watch_stats.dart';
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
        final stats = WatchStatsSnapshot.fromHistory(history);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, LucideIcons.flame, '${stats.streak}', stats.streak == 1 ? 'day streak' : 'day streak'),
              _chip(context, LucideIcons.tv, '${stats.showsThisMonth} shows', 'this month'),
              _chip(context, LucideIcons.clapperboard, '${stats.moviesThisMonth} movies', 'this month'),
              _chip(context, LucideIcons.listVideo, stats.episodesPerDay.toStringAsFixed(1), 'eps / day'),
              _chip(context, LucideIcons.play, '${stats.plays}', 'all-time plays'),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, IconData icon, String value, String label) {
    return Button(
      style: ButtonVariance.secondary,
      onPressed: () => context.push('/stats'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text('$value  $label', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
