import 'package:go_router/go_router.dart';
import 'package:petal/main.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      OutlineButton(density: ButtonDensity.icon, onPressed: () => PetalApp.rootNavigatorKey.currentContext?.pop(), child: const Icon(LucideIcons.chevronLeft));
}
