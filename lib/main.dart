import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit backend
  MediaKit.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(PetalApp());
}

class PetalApp extends StatefulWidget {
  const PetalApp({super.key});

  static final rootNavigatorKey = GlobalKey<NavigatorState>(); // ← root
  static final shellNavigatorKey = GlobalKey<NavigatorState>();

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
  Widget build(BuildContext context) => ShadcnApp.router(
    routerConfig: AppRouter.appRouter,
    theme: ThemeData(colorScheme: LegacyColorSchemes.darkRose(), radius: 0.7),
  );

  // @override
  // Widget build(BuildContext context) => MaterialApp(
  //   theme: ThemeData.light(),
  //   darkTheme: ThemeData.dark(),
  //   themeMode: ThemeMode.system,
  //   showPerformanceOverlay: true,
  //   home: ValueListenableBuilder(
  //     valueListenable: Api.healthy,
  //     builder: (context, healthy, child) {
  //       if (!healthy) {
  //         return Offline();
  //       } else {
  //         return ValueListenableBuilder<bool>(
  //           valueListenable: TraktApi.validSession,
  //           builder: (_, validSession, _) {
  //             if (!validSession) return TraktLoginPage();

  //             return const Navigation();
  //           },
  //         );
  //       }
  //     },
  //   ),
  // );
}
