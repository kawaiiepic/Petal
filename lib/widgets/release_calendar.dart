import 'package:petal/api/upcoming_releases.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:petal/widgets/home/release_tile.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ReleaseCalendar extends StatefulWidget {
  const ReleaseCalendar({super.key});

  @override
  State<ReleaseCalendar> createState() => _ReleaseCalendarState();
}

class _ReleaseCalendarState extends State<ReleaseCalendar> {
  late DateTime _selected = _date(DateTime.now());
  late DateTime _month = DateTime(_selected.year, _selected.month);

  @override
  void initState() {
    super.initState();
    UpcomingReleases.fetch().ignore();
  }

  static DateTime _date(DateTime day) => DateTime(day.year, day.month, day.day);

  void _moveMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    _selected = _month;
  });

  void _goToToday() => setState(() {
    _selected = _date(DateTime.now());
    _month = DateTime(_selected.year, _selected.month);
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: UpcomingReleases.items,
    builder: (context, items, _) {
      final byDay = <DateTime, List<UpcomingItem>>{};
      for (final item in items) {
        byDay.putIfAbsent(_date(item.airDate), () => []).add(item);
      }
      final today = _date(DateTime.now());
      final dayItems = byDay[_selected] ?? const <UpcomingItem>[];
      return HomeSection(
        title: 'Release calendar',
        editorial: true,
        trailing: Button.ghost(
          onPressed: _selected == today ? null : _goToToday,
          child: const Text('Today'),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final month = _monthPanel(context, byDay, today);
              final agenda = dayItems.isEmpty ? null : _agenda(dayItems);
              if (constraints.maxWidth < 630) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [month, if (agenda != null) agenda],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  SizedBox(width: 320, child: month),
                  if (agenda != null) Expanded(child: agenda),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  Widget _monthPanel(
    BuildContext context,
    Map<DateTime, List<UpcomingItem>> byDay,
    DateTime today,
  ) {
    final colors = Theme.of(context).colorScheme;
    final lead = _month.weekday % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = (lead + days + 6) ~/ 7;
    return LibraryPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        spacing: 4,
        children: [
          Row(
            children: [
              IconButton.ghost(
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  semanticLabel: 'Previous month',
                ),
                onPressed: () => _moveMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton.ghost(
                icon: const Icon(
                  LucideIcons.chevronRight,
                  semanticLabel: 'Next month',
                ),
                onPressed: () => _moveMonth(1),
              ),
            ],
          ),
          Row(
            children: [
              for (final label in const [
                'Su',
                'Mo',
                'Tu',
                'We',
                'Th',
                'Fr',
                'Sa',
              ])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
            ],
          ),
          for (var row = 0; row < rows; row++)
            Row(
              spacing: 2,
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _dayButton(
                      context,
                      row * 7 + col - lead + 1,
                      days,
                      byDay,
                      today,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayButton(
    BuildContext context,
    int number,
    int days,
    Map<DateTime, List<UpcomingItem>> byDay,
    DateTime today,
  ) {
    if (number < 1 || number > days) return const SizedBox(height: 38);
    final day = DateTime(_month.year, _month.month, number);
    final count = byDay[day]?.length ?? 0;
    final selected = day == _selected;
    final colors = Theme.of(context).colorScheme;
    final style = selected
        ? ButtonVariance.primary
        : day == today
        ? ButtonVariance.outline
        : ButtonVariance.ghost;
    return Semantics(
      label:
          '${_months[day.month - 1]} $number, $count ${count == 1 ? 'release' : 'releases'}',
      selected: selected,
      child: Button(
        style: style.withPadding(padding: EdgeInsets.zero),
        onPressed: () => setState(() => _selected = day),
        child: SizedBox(
          height: 38,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 3,
            children: [
              ExcludeSemantics(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: 4,
                child: count == 0
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? colors.primaryForeground
                              : colors.foreground,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _agenda(List<UpcomingItem> items) => LibraryPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            const Icon(LucideIcons.calendarDays, size: 18),
            Expanded(
              child: Text(
                '${_months[_selected.month - 1]} ${_selected.day}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SecondaryBadge(
              child: Text(
                '${items.length} ${items.length == 1 ? 'release' : 'releases'}',
              ),
            ),
          ],
        ),
        for (final item in items) ReleaseTile(item: item),
      ],
    ),
  );

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
