import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/utils/frame_safe_value_notifier.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DisposeWriter extends StatefulWidget {
  final VoidCallback write;
  const DisposeWriter({super.key, required this.write});
  @override
  State<DisposeWriter> createState() => _DisposeWriterState();
}

class _DisposeWriterState extends State<DisposeWriter> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
  @override
  void dispose() {
    widget.write();
    super.dispose();
  }
}

void main() {
  testWidgets('progress writes during disposal do not rebuild a locked tree', (
    tester,
  ) async {
    BackendCache.continueWatching.value = [];
    late StateSetter update;
    var visible = true;
    await tester.pumpWidget(
      ShadcnApp(
        home: Scaffold(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  ValueListenableBuilder<List<ContinueWatchingItem>>(
                    valueListenable: BackendCache.continueWatching,
                    builder: (_, items, _) => Text('Progress: ${items.length}'),
                  ),
                  if (visible)
                    DisposeWriter(
                      write: () {
                        BackendCache.continueWatching.value = [
                          MovieItem(tmdbId: 1, completion: .2),
                        ];
                        BackendCache.continueWatching.value = [
                          MovieItem(tmdbId: 1, completion: .3),
                          MovieItem(tmdbId: 2, completion: .4),
                        ];
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    update(() => visible = false);
    await tester.pump();
    expect(BackendCache.continueWatching.value.length, 2);
    await tester.pumpAndSettle();
    expect(find.text('Progress: 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    BackendCache.continueWatching.value = [];
  });

  testWidgets(
    'notifications queued during build coalesce and tolerate notifier disposal',
    (tester) async {
      final value = FrameSafeValueNotifier(0);
      var notifications = 0;
      value.addListener(() => notifications++);
      await tester.pumpWidget(
        Builder(
          builder: (_) {
            value.value = 1;
            value.value = 2;
            expect(value.value, 2);
            expect(notifications, 0);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(notifications, 1);
      await tester.pumpWidget(
        Builder(
          builder: (_) {
            value.value = 3;
            value.dispose();
            return const SizedBox.shrink();
          },
        ),
      );
      expect(notifications, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
