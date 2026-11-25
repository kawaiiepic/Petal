import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/home_layout.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/router/app_router.dart';
import 'package:petal/theme/app_theme.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/home/featured_autoplay.dart';
import 'package:petal/widgets/home/ios_featured_hero.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'support/recording_adapter.dart';

void main() {
  testWidgets('compact dock stays visible across Home, library, and Search', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 34);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'home.layout':
          '{"order":["catalogs"],"hidden":["stats","surprise",'
          '"upcoming","start","watchlist","liked","recent","stalled",'
          '"rewatched","because","downloads","friends","calendar"]}',
    });
    await HomeLayout.instance.load();
    // The download manager starts an app-lifetime network polling timer.
    await tester.runAsync(DownloadManager.load);
    BackendApi.dio = Dio()
      ..httpClientAdapter = (RecordingAdapter()
        ..respond = (request) {
          final uri = request.uri.toString();
          if (request.uri.path == '/addons') {
            return jsonBody({
              'result': [
                {
                  'id': 'phone-test',
                  'user_id': 'viewer',
                  'manifest_url': 'https://catalog.example/manifest.json',
                  'resources': ['catalog'],
                },
              ],
            });
          }
          if (uri.contains('manifest.json')) {
            return jsonBody({
              'catalogs': [
                {'id': 'top', 'type': 'movie', 'name': 'Popular'},
              ],
            });
          }
          if (uri.contains('catalog.example')) {
            return jsonBody({
              'metas': [
                {
                  'id': 'tt1',
                  'name': 'First feature',
                  'type': 'movie',
                  'poster': 'https://img.example/first.jpg',
                  'genres': ['Comedy'],
                },
                {
                  'id': 'tt2',
                  'name': 'Second feature',
                  'type': 'movie',
                  'poster': 'https://img.example/second.jpg',
                  'genres': ['Drama'],
                },
              ],
            });
          }
          return jsonBody({'result': []});
        });
    BackendApi.authState.setLoggedIn({'id': 'viewer'});
    BackendApi.authState.setInitializing(false);
    final router = AppRouter.appRouter;
    addTearDown(() {
      router.dispose();
      BackendApi.authState.setLoggedIn(null);
    });

    await tester.pumpWidget(
      glass.LiquidGlassWidgets.wrap(
        theme: glass.GlassThemeData.simple(quality: glass.GlassQuality.minimal),
        child: Sizer(
          maxTabletWidth: tvTabletBreakpoint,
          builder: (_, _, screen) => TvLayout(
            screenType: screen,
            child: ShadcnApp.router(
              routerConfig: router,
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData(colorScheme: AppTheme.desktopDarkScheme),
            ),
          ),
        ),
      ),
    );
    Future<void> draw() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    await draw();
    final hero = find.byType(IosFeaturedHero);
    expect(tester.getTopLeft(hero), Offset.zero);
    expect(tester.getSize(hero).width, 390);
    expect(tester.getSize(hero).height, closeTo(844 * .60, .1));
    final heading = find.descendant(of: hero, matching: find.text('Home'));
    expect(tester.getTopLeft(heading).dy, greaterThanOrEqualTo(54));
    expect(
      tester.getTopLeft(find.bySemanticsLabel('Account').first).dx,
      greaterThan(tester.getTopLeft(heading).dx),
    );
    Finder title(String text) =>
        find.descendant(of: hero, matching: find.text(text));
    expect(title('First feature').hitTestable(), findsOneWidget);
    await tester.pump(FeaturedAutoplay.interval);
    await draw();
    final carousel = tester.widget<PageView>(find.byType(PageView));
    expect(carousel.controller!.page, closeTo(1, .01));
    expect(tester.getCenter(title('Second feature')).dx, closeTo(195, 2));
    await tester.fling(find.byType(PageView), const Offset(240, 0), 950);
    await draw();
    await tester.pump(const Duration(milliseconds: 450));
    expect(carousel.controller!.page, closeTo(0, .01));
    expect(find.text('Chat with AI'), findsOneWidget);
    expect(find.text('Surprise me from my watchlist'), findsNothing);
    await tester.drag(hero, const Offset(0, -230));
    await draw();
    expect(find.text('Popular Movies'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is CatalogItemWidget && w.rank == 1),
      findsOneWidget,
    );

    Finder tab(String name) => find
        .descendant(
          of: find.byType(IosNavigationDock),
          matching: find.text(name),
        )
        .hitTestable();
    DockDestination selected() => tester
        .widget<IosNavigationDock>(find.byType(IosNavigationDock))
        .selectedDestination;
    for (final (label, heading, destination) in [
      ('Collection', 'Watchlist', DockDestination.collection),
      ('History', 'Playback history', DockDestination.history),
      ('Downloads', 'Download on Wi-Fi only', DockDestination.downloads),
    ]) {
      await tester.tap(tab(label));
      await draw();
      expect(find.text(heading).hitTestable(), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(tab('Home'), findsOneWidget);
      expect(selected(), destination);
      expect(router.canPop(), isFalse);
      if (destination != DockDestination.history) {
        expect(
          find.bySemanticsLabel('Account').first.hitTestable(),
          findsOneWidget,
        );
      }
    }
    await tester.tap(tab('Search'));
    await draw();
    expect(selected(), DockDestination.search);
    await tester.tap(find.text('Drama'));
    await draw();
    expect(find.text('All categories'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CatalogItemWidget && w.catalogItem?.id == 'tt2',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is CatalogItemWidget && w.catalogItem?.id == 'tt1',
      ),
      findsNothing,
    );
    await tester.enterText(find.byType(EditableText), 'Example');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await draw();
    expect(find.text('No results found.'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(selected(), DockDestination.search);
    await tester.tap(tab('Search'));
    await draw();
    expect(find.text('No results found.'), findsNothing);
    expect(find.text('All categories').hitTestable(), findsOneWidget);
    await tester.tap(tab('Home'));
    await draw();
    expect(hero, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }, variant: const TargetPlatformVariant({TargetPlatform.linux}));
}
