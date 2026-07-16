import 'package:flutter/services.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/discord.dart';
import 'package:petal/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit backend
  MediaKit.ensureInitialized();
  Discord.init();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(PetalApp());

  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
}

class PetalApp extends StatefulWidget {
  const PetalApp({super.key});

  static final rootNavigatorKey = GlobalKey<NavigatorState>(); // ← root
  static final shellNavigatorKey = GlobalKey<NavigatorState>();
  static final drawerNavigatorKey = GlobalKey<NavigatorState>();

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
    return Sizer(
      maxTabletWidth: 500,
      builder: (context, orientation, screenType) => ShadcnApp.router(
        routerConfig: AppRouter.appRouter,
        builder: (context, child) => DrawerOverlay(child: child!),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorSchemes.darkGray.pink, radius: 0.75, surfaceOpacity: 0.7, surfaceBlur: 12),
      ),
    );
  }
}
