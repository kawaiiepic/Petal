import 'package:go_router/go_router.dart';
import 'package:petal/main.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BackButton extends StatelessWidget {
  const BackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      density: ButtonDensity.icon,
      onPressed: () {
        final nav = PetalApp.rootNavigatorKey.currentContext;
        if (nav != null && nav.canPop()) nav.pop();
      },
      child: const Icon(LucideIcons.chevronLeft),
    );
  }
}
