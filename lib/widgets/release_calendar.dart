import 'package:go_router/go_router.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/upcoming_episodes.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ReleaseCalendar extends StatefulWidget {
  const ReleaseCalendar({super.key});

  @override
  State<ReleaseCalendar> createState() => _ReleaseCalendarState();
}

class _ReleaseCalendarState extends State<ReleaseCalendar> {
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    UpcomingReleases.fetch();
  }

  DateTime _key(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UpcomingReleases.items,
      builder: (context, items, _) {
        final byDay = <DateTime, List<UpcomingItem>>{};
        for (final item in items) {
          final day = _key(item.airDate);
          byDay.putIfAbsent(day, () => []).add(item);
        }
        final selected = _selected ?? DateTime(_month.year, _month.month, 1);
        final dayItems = byDay[_key(selected)] ?? const <UpcomingItem>[];
        return HomeSection(
          title: 'Release calendar',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton.ghost(
                              icon: const Icon(LucideIcons.chevronLeft),
                              onPressed: () => setState(() {
                                _month = DateTime(_month.year, _month.month - 1);
                                _selected = DateTime(_month.year, _month.month, 1);
                              }),
                            ),
                            Expanded(
                              child: Text(
                                '${_monthName(_month.month)} ${_month.year}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton.ghost(
                              icon: const Icon(LucideIcons.chevronRight),
                              onPressed: () => setState(() {
                                _month = DateTime(_month.year, _month.month + 1);
                                _selected = DateTime(_month.year, _month.month, 1);
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final label in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                              Expanded(
                                child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._rows(byDay),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _dayTitle(selected),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (dayItems.isEmpty)
                  Text('No new episodes this day', style: TextStyle(color: Colors.white.withValues(alpha: 0.55)))
                else
                  for (final item in dayItems) _ReleaseTile(item: item),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _rows(Map<DateTime, List<UpcomingItem>> byDay) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7;
    final rows = ((lead + daysInMonth + 6) / 7).floor();
    return [
      for (var row = 0; row < rows; row++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _cell(row * 7 + col, lead, daysInMonth, byDay)),
            ],
          ),
        ),
    ];
  }

  Widget _cell(int index, int lead, int daysInMonth, Map<DateTime, List<UpcomingItem>> byDay) {
    final dayNum = index - lead + 1;
    if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(height: 36);
    final day = DateTime(_month.year, _month.month, dayNum);
    final count = byDay[day]?.length ?? 0;
    final selected = _selected != null && _selected!.year == day.year && _selected!.month == day.month && _selected!.day == day.day;
    final today = DateTime.now();
    final isToday = today.year == day.year && today.month == day.month && today.day == day.day;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: () => setState(() => _selected = day),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: count == 0 ? Colors.white.withValues(alpha: 0.04) : const Color(0xFF7C4DFF).withValues(alpha: 0.28 + (count.clamp(1, 4) * 0.12)),
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: Colors.white, width: 1.5)
                : isToday
                ? Border.all(color: const Color(0xFF7C4DFF), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$dayNum', style: TextStyle(fontSize: 11, color: count == 0 ? Colors.white.withValues(alpha: 0.45) : Colors.white)),
              if (count > 0)
                Text('$count', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }

  String _dayTitle(DateTime day) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(day.year, day.month, day.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${day.month}/${day.day}/${day.year}';
  }

  static String _monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}

class _ReleaseTile extends StatelessWidget {
  final UpcomingItem item;

  const _ReleaseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => context.push('/series?tmdb=${item.tmdbId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.showName, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                'S${item.season} \u00b7 E${item.episode} - ${item.episodeName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
