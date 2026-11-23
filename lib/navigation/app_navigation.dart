import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/user_profile.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:petal/widgets/search/search_field.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class AppNavigation extends StatefulWidget {
  final Widget child;
  final GoRouterState state;

  const AppNavigation({super.key, required this.child, required this.state});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  final _homeScroll = ScrollController();

  @override
  void dispose() {
    _homeScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ios = usesPetalIosNavigation;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
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
                  if (!ios)
                    Button.text(
                      child: Icon(
                        BootstrapIcons.collectionFill,
                        size: iconSize,
                      ),
                      onPressed: () => context.push('/collection'),
                    ),
                  const UserProfile(),
                ],
              ),
            ),
          ),
        ],
        child: !ios
            ? widget.child
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      dark ? const Color(0xFF211429) : scheme.secondary,
                      scheme.background,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PrimaryScrollController(
                      controller: _homeScroll,
                      child: widget.child,
                    ),
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: IosNavigationDock(
                            onHome: () {
                              if (!_homeScroll.hasClients) return;
                              _homeScroll.animateTo(
                                _homeScroll.position.minScrollExtent,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            onCollection: () => context.push('/collection'),
                            onHistory: () => context.push('/history'),
                            onDownloads: () => context.push('/downloads'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
