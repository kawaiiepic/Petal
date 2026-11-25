import 'package:petal/widgets/library/library_page_frame.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/utils/history_timeline.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/library/history_play_card.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:petal/widgets/library/library_page_header.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(() => BackendCache.fetchWatchHistory(force: true));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = HistoryActions.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LibraryPageFrame(
    header: const LibraryPageHeader(
        title: 'Playback history',
        description: 'Revisit what you watched and manage your progress.',
        icon: LucideIcons.history,
      ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PetalButton.secondary(
                    leading: const Icon(LucideIcons.refreshCw, size: 16),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => BackendCache.fetchWatchHistory(force: true),
                          ),
                    child: const Text('Refresh'),
                  ),
                  ValueListenableBuilder(
                    valueListenable: HistoryActions.canUndo,
                    builder: (context, canUndo, _) => PetalButton.secondary(
                      leading: const Icon(LucideIcons.undo2, size: 16),
                      onPressed: !canUndo || _busy
                          ? null
                          : () => _run(HistoryActions.undo),
                      child: const Text('Undo last history edit'),
                    ),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error case final error?) Text(error),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: BackendCache.watchHistory,
            builder: (context, items, _) {
              final byDay = <DateTime?, List<HistoryPlay>>{};
              for (final play in historyTimeline(items)) {
                final date = play.date;
                (byDay[date == null ? null : _day(date)] ??= []).add(play);
              }
              if (byDay.isEmpty) {
                return _busy
                    ? const SizedBox.shrink()
                    : const Center(child: Text('No playback history yet.'));
              }
              final days = byDay.entries.toList();
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  return HomeSection(
                    key: ValueKey(day.key),
                    title: day.key == null ? 'Date unavailable' : _dayLabel(day.key!),
                    editorial: true,
                    child: MediaShelf(
                      orientation: Orientation.portrait,
                      scrollDirection: Axis.horizontal,
                      cardHeight: 212,
                      cardWidth: 118,
                      spacing: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: day.value.length,
                      itemBuilder: (context, index) {
                        final play = day.value[index];
                        return HistoryPlayCard(key: ValueKey(play.key), play: play);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  DateTime _day(DateTime timestamp) {
    final local = timestamp.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    if (day == _day(now)) return 'Today';
    if (day == DateTime(now.year, now.month, now.day - 1)) return 'Yesterday';
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }
}
