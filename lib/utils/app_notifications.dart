import 'package:petal/app/petal_app.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

abstract final class AppNotifications {
  static void sendNotification(Widget title, Widget subtitle) {
    showToast(
      context: PetalApp.rootNavigatorKey.currentContext!,
      builder: (context, overlay) => SurfaceCard(
        child: Basic(title: title, subtitle: subtitle),
      ),
    );
  }
}
