import 'package:petal/main.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BackButton extends StatelessWidget {
  const BackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      density: ButtonDensity.icon,
      onPressed: () {
        final ctx = PetalApp.rootNavigatorKey.currentContext ?? context;
        final nav = Navigator.of(ctx);
        if (nav.canPop()) nav.pop();
      },
      child: const Icon(LucideIcons.chevronLeft),
    );
  }
}
