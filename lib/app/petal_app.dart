import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:petal/api/api.dart';
import 'package:petal/navigation/tv_layout.dart';
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
        maxTabletWidth: tvTabletBreakpoint,
        builder: (context, orientation, screenType) {
          return TvLayout(
            screenType: screenType,
            child: ShadcnApp.router(
              routerConfig: AppRouter.appRouter,
              builder: (context, child) {
                final scheme = Theme.of(context).colorScheme;
                return ios.CupertinoTheme(
                  data: ios.CupertinoThemeData(
                    brightness: scheme.brightness,
                    primaryColor: scheme.primary,
                    primaryContrastingColor: scheme.primaryForeground,
                    scaffoldBackgroundColor: scheme.background,
                    barBackgroundColor: scheme.card,
                  ),
                  child: glass.GlassTheme(
                    data: const glass.GlassThemeData.ios27().copyWith(
                      brightness: scheme.brightness,
                    ),
                    child: DrawerOverlay(child: child!),
                  ),
                );
              },
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: _theme(ColorSchemes.lightGray.blue),
              darkTheme: _theme(AppTheme.desktopDarkScheme),
            ),
          );
        },
      ),
    );
  }
}

ThemeData _theme(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    radius: 1.0,
    surfaceOpacity: 1,
    surfaceBlur: 0,
  ).copyWith(platform: () => defaultTargetPlatform);
}
