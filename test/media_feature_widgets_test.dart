import 'package:flutter_test/flutter_test.dart';
import 'package:petal/pages/player/overlay/playback_recovery_overlay.dart';
import 'package:petal/pages/home_customization_page.dart';
import 'package:petal/api/home_layout.dart';
import 'package:petal/api/playback_preferences.dart';
import 'package:petal/widgets/settings/playback_preferences_card.dart';
import 'package:petal/models/stream_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

Widget app(Widget child) => ShadcnApp(home: Scaffold(child: child));
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets(
    'recovery exposes retry, source alternatives, and local-only recovery',
    (tester) async {
      var retries = 0, sources = 0, closes = 0;
      StreamItem? selected;
      final source = StreamItem.localFile(
        path: '/tmp/source.mp4',
        title: 'Alternative',
      );
      Widget recovery(bool offline) => app(
        PlaybackRecoveryOverlay(
          retry: () => retries++,
          findSources: () => sources++,
          close: () => closes++,
          choose: (value) => selected = value,
          offline: offline,
          loading: false,
          sources: offline ? null : [source],
        ),
      );
      await tester.pumpWidget(recovery(false));
      await tester.tap(find.text('Retry source'));
      await tester.pump();
      expect(retries, 1);
      await tester.tap(find.text('Choose another source'));
      await tester.pump();
      expect(sources, 1);
      await tester.tap(find.textContaining('Alternative'));
      await tester.pump();
      expect(selected, source);
      await tester.pumpWidget(recovery(true));
      expect(find.text('Choose another source'), findsNothing);
      await tester.tap(find.text('Close player'));
      await tester.pump();
      expect(closes, 1);
    },
  );
  testWidgets('playback preference editor saves validated values', (
    tester,
  ) async {
    await PlaybackPreferences.instance.update(
      audio: 'en',
      subtitle: 'en',
      enabled: true,
      rate: 1,
      delay: 0,
    );
    await tester.pumpWidget(
      app(const SingleChildScrollView(child: PlaybackPreferencesCard())),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'ja');
    await tester.enterText(fields.at(1), 'de');
    await tester.enterText(fields.at(2), '1.5');
    await tester.enterText(fields.at(3), '.4');
    await tester.tap(find.text('Save playback preferences'));
    await tester.pumpAndSettle();
    expect(PlaybackPreferences.instance.audioLanguage, 'ja');
    expect(PlaybackPreferences.instance.speed, 1.5);
    expect(PlaybackPreferences.instance.subtitleDelay, .4);
    await tester.enterText(fields.at(2), '900');
    await tester.tap(find.text('Save playback preferences'));
    await tester.pumpAndSettle();
    expect(PlaybackPreferences.instance.speed, 1.5);
    expect(find.textContaining('Enter language codes'), findsOneWidget);
  });
  testWidgets(
    'Home editor hides and reorders sections without removing the editor',
    (tester) async {
      await HomeLayout.instance.load();
      await HomeLayout.instance.reset();
      await tester.pumpWidget(app(const HomeCustomizationPage()));
      await tester.pumpAndSettle();
      final row = find
          .ancestor(of: find.text('On Deck'), matching: find.byType(Row))
          .first;
      final toggle = find.descendant(of: row, matching: find.byType(Switch));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(HomeLayout.instance.hidden, contains('deck'));
      final before = HomeLayout.instance.order.indexOf('deck');
      await tester.tap(
        find.descendant(of: row, matching: find.byIcon(LucideIcons.arrowUp)),
      );
      await tester.pumpAndSettle();
      expect(HomeLayout.instance.order.indexOf('deck'), before - 1);
    },
  );
}
