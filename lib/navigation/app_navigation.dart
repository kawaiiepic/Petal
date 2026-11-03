import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/navigation/user_profile.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:petal/widgets/search/search_field.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class AppNavigation extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AppNavigation({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final iconSize = AppTypography.normalIconSize;
    final logoSize = (iconSize + 10).clamp(24.0, 32.0);

    return RefreshTrigger(
      key: PetalApp.refreshTriggerKey,
      onRefresh: () async {
        await Future.wait([
          BackendCache.fetchContinueWatching(force: true),
          BackendCache.fetchWatchHistory(force: true),
          UserLibrary.load(force: true),
        ]);
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
                  const Expanded(child: SearchField()),
                  const SizedBox(width: 8),
                  Button.text(
                    child: Icon(BootstrapIcons.collectionFill, size: iconSize),
                    onPressed: () => PetalApp.rootNavigatorKey.currentContext
                        ?.push('/collection'),
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
