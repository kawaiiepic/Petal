import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/navigation/desktop_tv_shell.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/tv_layout.dart';
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
    final colors = Theme.of(context).colorScheme;
    final location = widget.state.uri.path;
    final home = location == '/';
    final search = location == '/search';
    final selectedDestination = DockDestination.values.firstWhere(
      (destination) => destination.path == location,
    );
    final hasQuery = widget.state.uri.queryParameters['q']?.isNotEmpty ?? false;
    final dockVisible = MediaQuery.viewInsetsOf(context).bottom == 0;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    void navigate(String path) {
      if (path != location || (search && hasQuery)) {
        context.go(path);
      } else if (home && _homeScroll.hasClients) {
        _homeScroll.animateTo(
          _homeScroll.position.minScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }

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
        child: !TvLayout.isCompact(context)
            ? SafeArea(
                child: DesktopTvShell(
                  location: location,
                  onNavigate: navigate,
                  child: widget.child,
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.brightness == Brightness.dark
                          ? const Color(0xFF15171B)
                          : colors.secondary,
                      colors.background,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    home
                        ? PrimaryScrollController(
                            controller: _homeScroll,
                            child: widget.child,
                          )
                        : Padding(
                            // Search already reserves space in its scroll view.
                            padding: EdgeInsets.only(
                              bottom: !search && dockVisible
                                  ? bottomInset + IosNavigationDock.clearance
                                  : 0,
                            ),
                            child: widget.child,
                          ),
                    if (dockVisible)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: bottomInset + 8,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: IosNavigationDock(
                            selectedDestination: selectedDestination,
                            onSelected: (destination) =>
                                navigate(destination.path),
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
