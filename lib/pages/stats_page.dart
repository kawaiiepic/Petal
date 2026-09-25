import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/watch_stats.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
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
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
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
          final selected = _selectedDay ?? DateTime(_month.year, _month.month, 1);
          final dayItems = stats.titlesByDay[DateTime(selected.year, selected.month, selected.day)] ?? const <DayWatch>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _stat(width, 'Shows', '${stats.shows}', 'all time'),
                      _stat(width, 'Movies', '${stats.movies}', 'all time'),
                      _stat(width, 'Episodes', '${stats.episodes}', 'logged'),
                      _stat(width, 'Plays', '${stats.plays}', 'all time'),
                      _stat(width, 'Shows', '${stats.showsThisMonth}', 'this month'),
                      _stat(width, 'Movies', '${stats.moviesThisMonth}', 'this month'),
                      _stat(width, 'Episodes', '${stats.episodesThisMonth}', 'this month'),
                      _stat(width, 'Streak', '${stats.streak}', stats.streak == 1 ? 'day' : 'days'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              WatchCalendar(
                stats: stats,
                selectedDay: _selectedDay,
                onMonthChanged: (value) => setState(() {
                  _month = value;
                  _selectedDay = DateTime(value.year, value.month, 1);
                }),
                onDaySelected: (value) => setState(() => _selectedDay = value),
              ),
              const SizedBox(height: 16),
              Text(
                '${selected.month}/${selected.day}/${selected.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (dayItems.isEmpty)
                Text('Nothing logged this day', style: TextStyle(color: Colors.white.withValues(alpha: 0.55)))
              else
                for (final item in dayItems) _DayWatchTile(item: item),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(double width, String title, String value, String subtitle) {
    return SizedBox(
      width: width,
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

class _DayWatchTile extends StatelessWidget {
  final DayWatch item;

  const _DayWatchTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final name = snapshot.hasData
            ? (isShow ? (snapshot.data as dynamic).name as String? : (snapshot.data as dynamic).title as String?)
            : null;
        final detail = isShow && item.season != null && item.episode != null ? 'S${item.season}E${item.episode}' : 'Movie';
        return Button.ghost(
          alignment: Alignment.centerLeft,
          onPressed: () => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? detail, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(detail, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
              ],
            ),
          ),
        );
      },
    );
  }
}
