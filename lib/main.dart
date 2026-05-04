import 'package:petal/api/api.dart';
import 'package:petal/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

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
  Widget build(BuildContext context) => Sizer(
    builder: (context, orientation, screenType) => ShadcnApp.router(
      routerConfig: AppRouter.appRouter,
      theme: ThemeData(colorScheme: LegacyColorSchemes.darkRose(), radius: 0.7),
    ),
  );
}
