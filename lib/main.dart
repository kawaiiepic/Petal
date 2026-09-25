import 'package:flutter/services.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/api/query_proxy.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/pages/settings.dart';
import 'package:petal/router/router.dart';
import 'package:petal/widgets/edge_back_swipe.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.load();
  await QueryProxy.load();
  await UserLibrary.load();

  MediaKit.ensureInitialized();
  Discord.init();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(PetalApp());

  windowManager.setTitleBarStyle(TitleBarStyle.hidden);
}

class PetalApp extends StatefulWidget {
  const PetalApp({super.key});

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>();
  static final drawerNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<RefreshTriggerState> refreshTriggerKey = GlobalKey<RefreshTriggerState>();

  @override
  State<PetalApp> createState() => _PetalState();
}

class _PetalState extends State<PetalApp> {
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
        builder: (context, orientation, screenType) => ShadcnApp.router(
          routerConfig: AppRouter.appRouter,
          builder: (context, child) => DrawerOverlay(child: EdgeBackSwipe(child: child!)),
          debugShowCheckedModeBanner: false,
          scaling: AdaptiveScaling.mobile,
          themeMode: mode,
          theme: _theme(ColorSchemes.lightGray.pink),
          darkTheme: _theme(ColorSchemes.darkGray.pink),
        ),
      ),
    );
  }
}

ThemeData _theme(ColorScheme scheme) {
  return ThemeData(colorScheme: scheme, radius: 0.75, surfaceOpacity: 1, surfaceBlur: 0).copyWith(platform: () => TargetPlatform.linux);
}
