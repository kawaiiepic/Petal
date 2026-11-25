import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('shelf headings are static and trailing actions still work', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      ShadcnApp(
        home: Center(
          child: HomeSection(
            title: 'Continue Watching',
            editorial: true,
            trailing: Button(
              style: ButtonVariance.ghost,
              onPressed: () => tapped++,
              child: const Text('See all'),
            ),
            child: const Text('Episode card'),
          ),
        ),
      ),
    );
    expect(find.byType(Button), findsOneWidget);
    await tester.tap(find.text('Continue Watching'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Episode card'), findsOneWidget);
    await tester.tap(find.text('See all'));
    expect(tapped, 1);
  });

  testWidgets('remaining caption aligns with the right artwork inset', (
    tester,
  ) async {
    const overlay = Key('overlay');
    for (final playback in [true, false]) {
      await tester.pumpWidget(
        ShadcnApp(
          home: Center(
            child: SizedBox(
              key: overlay,
              width: 320,
              child: WatchMetaOverlay(
                playback: playback,
                progress: .15,
                episodeLabel: 'S2 · E3',
                durationLabel: '45m',
                remainingLabel: '694 left',
              ),
            ),
          ),
        ),
      );
      final edge = tester.getRect(find.byKey(overlay)).right;
      final captionEdge = tester.getRect(find.text('694 left')).right;
      expect(captionEdge, closeTo(edge - (playback ? 10 : 8), .1));
    }
  });
}
