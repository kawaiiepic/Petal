import 'package:go_router/go_router.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/watch_stats.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
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
          _StatCard(icon: LucideIcons.flame, value: '${stats.streak}', label: stats.streak == 1 ? 'day streak' : 'day streak'),
          _StatCard(icon: LucideIcons.tv, value: '${stats.showsThisMonth}', label: 'shows this month'),
          _StatCard(icon: LucideIcons.clapperboard, value: '${stats.moviesThisMonth}', label: 'movies this month'),
          _StatCard(icon: LucideIcons.listVideo, value: stats.episodesPerDay.toStringAsFixed(1), label: 'eps / day'),
          _StatCard(icon: LucideIcons.play, value: '${stats.plays}', label: 'all-time plays'),
        ];
        return HomeSection(
          title: 'Stats',
          trailing: Button.ghost(
            onPressed: () => context.push('/stats'),
            child: const Text('See all'),
          ),
          child: SizedBox(
            height: 14.h,
            child: ScrollableWidget(
              controller: _controller,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/stats'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16),
              const Spacer(),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}
