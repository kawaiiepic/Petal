import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/models/library/collection_section.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/pages/collection_page.dart';
import 'package:petal/pages/collection_home_page.dart';
import 'package:petal/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';
import 'support/recording_adapter.dart';

void main() {
  testWidgets('desktop collection sidebar switches between every category', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final adapter = RecordingAdapter()..respond = (_) => jsonBody({'result': []});
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
    BackendApi.authState.setLoggedIn({'id': 'viewer'});
    BackendApi.authState.setInitializing(false);
    final router = AppRouter.appRouter;
    router.go(CollectionSection.watching.route);
    addTearDown(() {
      router.dispose();
      BackendApi.authState.setLoggedIn(null);
    });
    await tester.pumpWidget(glass.LiquidGlassWidgets.wrap(
      theme: glass.GlassThemeData.simple(quality: glass.GlassQuality.minimal),
      child: Sizer(maxTabletWidth: tvTabletBreakpoint,
        builder: (_, _, screen) => TvLayout(screenType: screen,
          child: ShadcnApp.router(routerConfig: router))),
    ));
    Future<void> draw() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
    }
    await draw();
    for (final section in [
      CollectionSection.watchlist, CollectionSection.watching,
      CollectionSection.liked, CollectionSection.watched,
      CollectionSection.planned, CollectionSection.watchlist,
    ]) {
      final button = find.byKey(ValueKey('collection-nav:${section.name}'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await draw();
      expect(router.state.uri.path, section.route);
      expect(tester.widget<CollectionPage>(find.byType(CollectionPage)).section, section);
      expect(tester.widget<CollectionHomePage>(find.byType(CollectionHomePage)).section, section);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));
}
