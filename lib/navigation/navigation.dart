import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/main.dart';
import 'package:petal/navigation/profile.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Navigation extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const Navigation({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final iconSize = Misc.normalIconSize;
    final logoSize = (iconSize + 10).clamp(24.0, 32.0);

    return RefreshTrigger(
      key: PetalApp.refreshTriggerKey,
      onRefresh: () async {
        await BackendCache.fetchContinueWatching();
      },
      child: Scaffold(
        headers: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/logo-clean.svg',
                    height: logoSize,
                    width: logoSize,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Search()),
                  const SizedBox(width: 8),
                  Button.text(
                    child: Icon(BootstrapIcons.collectionFill, size: iconSize),
                    onPressed: () => PetalApp.rootNavigatorKey.currentContext?.push('/collection'),
                  ),
                  const UserProfile(),
                ],
              ),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}
