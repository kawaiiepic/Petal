import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/ios/ios_context_menu.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets(
    'right click opens the frosted menu without activating the card',
    (tester) async {
      var primary = 0;
      var selected = 0;
      const trigger = Key('trigger');
      await tester.pumpWidget(
        ShadcnApp(
          home: Scaffold(
            child: Center(
              child: PetalContextMenu(
                items: [
                  MenuButton(
                    onPressed: (_) => selected++,
                    child: const Text('Select source'),
                  ),
                ],
                child: GestureDetector(
                  key: trigger,
                  onTap: () => primary++,
                  child: const Text('Play'),
                ),
              ),
            ),
          ),
        ),
      );

      Future<void> open() async {
        await tester.tap(
          find.byKey(trigger),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await tester.pumpAndSettle();
      }

      await open();
      expect(primary, 0);
      final popup = tester.widget<MenuPopup>(find.byType(MenuPopup));
      expect(popup.theme!.borderRadius, BorderRadius.circular(22));
      expect(popup.theme!.surfaceBlur, greaterThan(0));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MenuPopup), findsNothing);
      expect(selected, 0);

      await open();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(MenuPopup), findsNothing);

      await open();
      await tester.tap(find.text('Select source'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.byType(MenuPopup), findsNothing);

      await tester.tap(find.byKey(trigger));
      expect(primary, 1);
    },
  );

  testWidgets('iOS long press opens the same menu near a screen edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShadcnApp(
        theme: const ThemeData().copyWith(platform: () => TargetPlatform.iOS),
        home: const Scaffold(
          child: Align(
            alignment: Alignment.bottomRight,
            child: PetalContextMenu(
              items: [MenuButton(child: Text('More info'))],
              child: Text('Poster'),
            ),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Poster'));
    await tester.pumpAndSettle();
    final popup = tester.getRect(find.byType(MenuPopup));
    final screen = tester.getRect(find.byType(PetalContextMenu).first);
    expect(popup.right, lessThanOrEqualTo(screen.right));
    expect(popup.bottom, lessThanOrEqualTo(screen.bottom));
    expect(find.text('More info').hitTestable(), findsOneWidget);
  });
}
