import 'package:petal/api/api.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/pages/splash.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Offline extends StatelessWidget {
  const Offline({super.key});

  @override
  Widget build(BuildContext context) {
    Api.healthy.addListener(() {
      if (Api.healthy.value) {
        context.go('/');
      }
    });
    return SplashScreen();
  }
}
