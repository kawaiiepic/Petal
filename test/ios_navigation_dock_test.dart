import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('iOS dock fits a compact phone and exposes all destinations', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final pressed = <String>[];

    await tester.pumpWidget(
      glass.LiquidGlassWidgets.wrap(
        theme: glass.GlassThemeData.simple(quality: glass.GlassQuality.minimal),
        child: ShadcnApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(colorScheme: AppTheme.darkScheme),
        home: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: IosNavigationDock(
              onHome: () => pressed.add('Home'),
              onCollection: () => pressed.add('Collection'),
              onHistory: () => pressed.add('History'),
              onDownloads: () => pressed.add('Downloads'),
            ),
          ),
        ),
      )),
    );
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Collection', 'History', 'Downloads']) {
      final item = find.text(label);
      expect(item.hitTestable(), findsOneWidget);
      await tester.tap(item);
    }
    expect(pressed, ['Home', 'Collection', 'History', 'Downloads']);
    expect(tester.takeException(), isNull);
  });
}
