import 'package:go_router/go_router.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/watch_stats.dart';
import 'package:petal/widgets/watch_calendar.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    BackendCache.fetchWatchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.watchHistory,
      builder: (context, history, _) {
        final stats = WatchStatsSnapshot.fromHistory(history, month: _month);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Your stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Button.link(onPressed: () => context.push('/stats'), child: const Text('View all')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(LucideIcons.tv, '${stats.showsThisMonth} shows', 'this month'),
                  _chip(LucideIcons.clapperboard, '${stats.moviesThisMonth} movies', 'this month'),
                  _chip(LucideIcons.listVideo, stats.episodesPerDay.toStringAsFixed(1), 'eps / day'),
                  _chip(LucideIcons.play, '${stats.plays}', 'all-time plays'),
                ],
              ),
              const SizedBox(height: 12),
              WatchCalendar(stats: stats, onMonthChanged: (value) => setState(() => _month = value)),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
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
