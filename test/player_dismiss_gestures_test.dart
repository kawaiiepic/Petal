import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/widgets/player_dismiss_gestures.dart';

void main() {
  testWidgets('dismisses the fullscreen route by pulling down or from left', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PlayerDismissGestures(
                  onDismiss: () => Navigator.of(context).pop(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (_) {},
                    child: const Center(child: Text('Playing')),
                  ),
                ),
              ),
            ),
            child: const Text('Open player'),
          ),
        ),
      ),
    );

    for (final (start, delta) in [
      (const Offset(200, 210), const Offset(0, 135)),
      (const Offset(10, 210), const Offset(130, 0)),
    ]) {
      await tester.tap(find.text('Open player'));
      await tester.pumpAndSettle();
      expect(find.text('Playing'), findsOneWidget);
      await tester.dragFrom(start, delta);
      await tester.pumpAndSettle();
      expect(find.text('Playing'), findsNothing);
    }
  });

  testWidgets('does not dismiss on seeking, upward swipes, or lower controls', (
    tester,
  ) async {
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerDismissGestures(
          onDismiss: () => dismissed++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.dragFrom(const Offset(150, 280), const Offset(180, 0));
    await tester.dragFrom(const Offset(150, 280), const Offset(0, -160));
    await tester.dragFrom(const Offset(150, 470), const Offset(0, 100));
    await tester.tapAt(const Offset(10, 200));
    expect(dismissed, 0);
  });
}
