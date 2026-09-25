import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/watch_stats.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/watch_calendar.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
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
    return Scaffold(
      headers: [
        AppBar(leading: const [BackButton()], title: const Text('Stats')),
      ],
      child: ValueListenableBuilder(
        valueListenable: BackendCache.watchHistory,
        builder: (context, history, _) {
          final stats = WatchStatsSnapshot.fromHistory(history, month: _month);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _stat('Shows', '${stats.shows}', 'all time'),
                  _stat('Movies', '${stats.movies}', 'all time'),
                  _stat('Episodes', '${stats.episodes}', 'logged'),
                  _stat('Plays', '${stats.plays}', 'all time'),
                  _stat('Shows', '${stats.showsThisMonth}', 'this month'),
                  _stat('Movies', '${stats.moviesThisMonth}', 'this month'),
                  _stat('Episodes', '${stats.episodesThisMonth}', 'this month'),
                  _stat('Average', stats.episodesPerDay.toStringAsFixed(2), 'episodes / day'),
                ],
              ),
              const SizedBox(height: 16),
              WatchCalendar(stats: stats, onMonthChanged: (value) => setState(() => _month = value)),
              const SizedBox(height: 12),
              Text(
                'Month activity is based on the last update time we have for each title. Individual episode dates are not stored yet.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String title, String value, String subtitle) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ),
    );
  }
}
