import 'package:petal/api/watch_stats.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchCalendar extends StatelessWidget {
  final WatchStatsSnapshot stats;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onMonthChanged;
  final ValueChanged<DateTime>? onDaySelected;

  const WatchCalendar({super.key, required this.stats, this.selectedDay, this.onMonthChanged, this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final month = stats.month;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7;
    final cells = lead + daysInMonth;
    final rows = ((cells + 6) / 7).floor();
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final max = stats.activityByDay.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton.ghost(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: onMonthChanged == null ? null : () => onMonthChanged!(DateTime(month.year, month.month - 1)),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(month.month)} ${month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton.ghost(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: onMonthChanged == null ? null : () => onMonthChanged!(DateTime(month.year, month.month + 1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final label in labels)
                  Expanded(
                    child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var row = 0; row < rows; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _cell(
                          index: row * 7 + col,
                          lead: lead,
                          daysInMonth: daysInMonth,
                          month: month,
                          max: max,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell({required int index, required int lead, required int daysInMonth, required DateTime month, required int max}) {
    final dayNum = index - lead + 1;
    if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(height: 32);
    final day = DateTime(month.year, month.month, dayNum);
    final count = stats.activityByDay[day] ?? 0;
    final selected = selectedDay != null && selectedDay!.year == day.year && selectedDay!.month == day.month && selectedDay!.day == day.day;
    final intensity = count == 0 ? 0.08 : (0.18 + (count / max) * 0.82).clamp(0.18, 1.0);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: onDaySelected == null ? null : () => onDaySelected!(day),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withValues(alpha: intensity),
            borderRadius: BorderRadius.circular(6),
            border: selected ? Border.all(color: Colors.white, width: 1.5) : null,
          ),
          child: Text('$dayNum', style: TextStyle(fontSize: 11, color: count == 0 ? Colors.white.withValues(alpha: 0.45) : Colors.white)),
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}
