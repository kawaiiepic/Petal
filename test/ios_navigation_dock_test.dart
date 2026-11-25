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
                selectedDestination: DockDestination.history,
                onSelected: (destination) => pressed.add(destination.label),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const destinations = [
      'Home',
      'Collection',
      'History',
      'Downloads',
      'Search',
    ];
    for (final label in destinations) {
      final item = find.text(label).hitTestable();
      expect(item, findsOneWidget);
      await tester.tap(item);
    }
    expect(pressed, destinations);
    expect(
      tester
          .widget<glass.GlassTabBar>(find.byType(glass.GlassTabBar))
          .selectedIndex,
      2,
    );
    expect(tester.takeException(), isNull);
  });
}
