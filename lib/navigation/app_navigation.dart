import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:petal/api/retained_player.dart';
import 'package:petal/navigation/retained_player_button.dart';
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
  DockDestination _lastDestination = DockDestination.home;
  bool _miniCollapsed = false;
  double _scrollTravel = 0;
  ScrollDirection _scrollDirection = ScrollDirection.idle;

  bool _onMiniScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical ||
        RetainedPlayer.instance.available.value == null) return false;
    if (notification is ScrollEndNotification) {
      _scrollTravel = 0;
      _scrollDirection = ScrollDirection.idle;
      return false;
    }
    if (notification is! ScrollUpdateNotification) return false;
    final delta = notification.scrollDelta ?? 0;
    if (delta == 0 || notification.metrics.outOfRange) return false;
    if (notification.metrics.pixels <= notification.metrics.minScrollExtent + 2) {
      _scrollTravel = 0;
      if (_miniCollapsed) setState(() => _miniCollapsed = false);
      return false;
    }
    final direction = delta > 0 ? ScrollDirection.reverse : ScrollDirection.forward;
    if (_scrollDirection != direction) {
      _scrollDirection = direction;
      _scrollTravel = 0;
    }
    _scrollTravel += delta.abs();
    if (_scrollTravel >= 24) {
      final collapsed = direction == ScrollDirection.reverse;
      if (_miniCollapsed != collapsed) setState(() => _miniCollapsed = collapsed);
      _scrollTravel = 0;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.uri.path != widget.state.uri.path) {
      _miniCollapsed = false;
      _scrollTravel = 0;
      _scrollDirection = ScrollDirection.idle;
    }
  }

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
    final overview = location == '/series' || location == '/movie';
    final selectedDestination = DockDestination.values.firstWhere(
      (destination) => destination.path == location,
      orElse: () => _lastDestination,
    );
    _lastDestination = selectedDestination;
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

    return ValueListenableBuilder(
      valueListenable: RetainedPlayer.instance.available,
      builder: (context, retained, _) {
      final miniVisible = retained != null && dockVisible;
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
                  location: selectedDestination.path,
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
                    NotificationListener<ScrollNotification>(
                      onNotification: _onMiniScroll,
                      child: home
                        ? PrimaryScrollController(
                            controller: _homeScroll,
                            child: widget.child,
                          )
                        : Padding(
                            // Search already reserves space in its scroll view.
                            padding: EdgeInsets.only(
                              bottom: !search && !overview && dockVisible
                                  ? bottomInset + IosNavigationDock.clearance + (miniVisible ? 62 : 0)
                                  : 0,
                            ),
                            child: widget.child,
                          ),
                    ),
                    if (miniVisible)
                      Positioned(left: 12, right: 12, bottom: bottomInset + 76,
                        child: Align(alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOutCubic,
                            width: _miniCollapsed ? 168 : 440,
                            child: RetainedPlayerButton(media: retained!, mobile: true,
                              collapsed: _miniCollapsed)))),
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
    });
  }
}
