import 'package:flutter/services.dart';
import 'package:petal/api/api.dart';
import 'package:petal/router/app_router.dart';
import 'package:petal/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class PetalApp extends StatefulWidget {
  const PetalApp({super.key});

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>();
  static final drawerNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<RefreshTriggerState> refreshTriggerKey =
      GlobalKey<RefreshTriggerState>();

  @override
  State<PetalApp> createState() => _PetalAppState();
}

class _PetalAppState extends State<PetalApp> {
  @override
  void initState() {
    super.initState();
    Api.initApi();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return ValueListenableBuilder(
      valueListenable: AppTheme.mode,
      builder: (context, mode, _) => Sizer(
        maxTabletWidth: 500,
        builder: (context, orientation, screenType) {
          double screenWidth = MediaQuery.sizeOf(context).width;
          return ShadcnApp.router(
            key: ValueKey(screenWidth),
            routerConfig: AppRouter.appRouter,
            builder: (context, child) => DrawerOverlay(child: child!),
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: _theme(ColorSchemes.lightGray.pink),
            darkTheme: _theme(ColorSchemes.darkGray.pink),
          );
        },
      ),
    );
  }
}

ThemeData _theme(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    radius: 0.75,
    surfaceOpacity: 1,
    surfaceBlur: 0,
  ).copyWith(platform: () => TargetPlatform.linux);
}
