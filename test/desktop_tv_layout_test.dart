import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/home_layout.dart';
import 'package:petal/navigation/desktop_tv_shell.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/router/app_router.dart';
import 'package:petal/theme/app_theme.dart';
import 'package:petal/widgets/arrow_button.dart';
import 'package:petal/widgets/home/desktop_featured_hero.dart';
import 'package:petal/widgets/home/featured_autoplay.dart';
import 'package:petal/widgets/home/featured_pagination.dart';
import 'package:petal/widgets/search/search_discovery.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'support/recording_adapter.dart';

void main() {
  testWidgets('desktop sidebar stays mounted and the featured carousel works', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 740);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'home.layout':
          '{"order":["catalogs","surprise"],"hidden":["stats",'
          '"upcoming","start","watchlist","liked","recent","stalled",'
          '"rewatched","because","downloads","friends","calendar"]}',
    });
    await HomeLayout.instance.load();
    final adapter = RecordingAdapter()
      ..respond = (request) {
        final uri = request.uri.toString();
        if (request.uri.path == '/addons') {
          return jsonBody({
            'result': [
              {
                'id': 'example.catalog',
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
                'id': 'tt123',
                'name': 'First feature',
                'type': 'movie',
                'background': 'https://img.example/first.jpg',
                'genres': ['Drama'],
              },
              {
                'id': 'tt456',
                'name': 'Second feature',
                'type': 'movie',
                'background': 'https://img.example/second.jpg',
              },
              for (var index = 3; index <= 18; index++)
                {
                  'id': 'tt900$index',
                  'name': 'Feature $index',
                  'type': 'movie',
                  'background': 'https://img.example/feature-$index.jpg',
                },
            ],
          });
        }
        return jsonBody({'result': []});
      };
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
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
    // Artwork loading can shimmer while the widget-test HTTP client is mocked.
    Future<void> drawFrames() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
    }

    await drawFrames();
    final shell = find.byType(DesktopTvShell);
    Finder button(String label) => find.byWidgetPredicate(
      (widget) => widget is glass.GlassButton && widget.label == label,
    );
    expect(shell, findsOneWidget);
    final bounds = tester.getRect(shell);
    final hero = tester.getRect(find.byType(DesktopFeaturedHero));
    expect(hero.top, bounds.top);
    expect(hero.left, bounds.left + tvDesktopSidebarWidth);
    expect(hero.right, bounds.right);
    expect(hero.height, closeTo(bounds.height * .55, .1));
    final surprise = tester.getRect(find.text('Surprise me from my watchlist'));
    final chat = find.text('Chat with AI');
    final chatBounds = tester.getRect(chat);
    expect(surprise.top, greaterThan(hero.bottom));
    expect(chatBounds.left, greaterThan(surprise.right));
    expect(chatBounds.center.dy, closeTo(surprise.center.dy, .1));
    expect(
      chatBounds.bottom,
      lessThan(tester.getTopLeft(find.text('Popular Movies')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Popular Movies')).dx,
      greaterThan(tvDesktopSidebarWidth),
    );
    final shellElement = tester.element(shell);
    expect(tester.widget<glass.GlassButton>(button('Home')).isSelected, isTrue);
    FeaturedPagination pager() =>
        tester.widget<FeaturedPagination>(find.byType(FeaturedPagination));
    expect(pager().count, 8);
    expect(pager().selectedIndex, 0);
    final previous = find.widgetWithIcon(ArrowButton, LucideIcons.arrowBigLeft);
    final next = find.widgetWithIcon(ArrowButton, LucideIcons.arrowBigRight);
    final previousBounds = tester.getRect(previous.hitTestable());
    final nextBounds = tester.getRect(next.hitTestable());
    expect(previousBounds.center.dy, closeTo(hero.center.dy, .1));
    expect(nextBounds.center.dy, closeTo(hero.center.dy, .1));
    expect(previousBounds.left, closeTo(hero.left + 8, .1));
    expect(nextBounds.right, closeTo(hero.right - 8, .1));
    await tester.tap(previous.hitTestable());
    await drawFrames();
    expect(pager().selectedIndex, 7);
    await tester.tap(next.hitTestable());
    await drawFrames();
    expect(pager().selectedIndex, 0);
    await tester.pump(FeaturedAutoplay.interval);
    await drawFrames();
    expect(pager().selectedIndex, 1);
    expect(find.text('Second feature').hitTestable(), findsWidgets);
    final first = find.bySemanticsLabel('Featured title 1 of 8');
    final last = find.bySemanticsLabel('Featured title 8 of 8');
    expect(
      tester.getCenter(last).dx - tester.getCenter(first).dx,
      lessThan(140),
    );
    await tester.tap(last);
    await drawFrames();
    expect(pager().selectedIndex, 7);
    await tester.tap(first);
    await drawFrames();
    expect(pager().selectedIndex, 0);

    await tester.tap(chat);
    await drawFrames();
    final unavailable = find.text('AI chat isn’t available in Petal yet.');
    expect(unavailable, findsOneWidget);
    await tester.tap(find.text('Close'));
    await drawFrames();
    expect(unavailable, findsNothing);

    await tester.tap(button('History'));
    await drawFrames();
    expect(find.text('Playback history'), findsOneWidget);
    expect(tester.element(shell), same(shellElement));
    expect(
      tester.widget<glass.GlassButton>(button('History')).isSelected,
      isTrue,
    );

    tester.view.physicalSize = const Size(680, 740);
    await tester.pumpAndSettle();
    expect(shell, findsNothing);
    expect(find.text('Playback history'), findsOneWidget);
    tester.view.physicalSize = const Size(1100, 740);
    await tester.pumpAndSettle();
    expect(
      tester.widget<glass.GlassButton>(button('History')).isSelected,
      isTrue,
    );
    await tester.tap(button('Home'));
    await drawFrames();
    expect(pager().selectedIndex, 0);

    await tester.tap(button('Search'));
    await drawFrames();
    expect(find.byType(SearchDiscovery), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Example');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await drawFrames();
    expect(find.text('No results found.'), findsOneWidget);
    expect(
      tester.widget<glass.GlassButton>(button('Home')).isSelected,
      isFalse,
    );
    await tester.tap(button('Home'));
    await drawFrames();
    expect(pager().selectedIndex, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));
}
