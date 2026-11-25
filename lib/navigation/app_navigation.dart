import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
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

  Widget _compactDockAction(IconData icon) => glass.GlassButton(
    icon: Icon(icon, size: 24, color: Theme.of(context).colorScheme.foreground),
    onTap: () => setState(() {
      _miniCollapsed = false;
      _scrollTravel = 0;
      _scrollDirection = ScrollDirection.idle;
    }),
    width: 58, height: 58,
    useOwnLayer: true,
    shape: const glass.LiquidOval(),
    style: glass.GlassButtonStyle.filled,
    stretch: .15,
  );

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
      orElse: () => location.startsWith('/collection/') ? DockDestination.collection : _lastDestination,
    );
    _lastDestination = selectedDestination;
    final hasQuery = widget.state.uri.queryParameters['q']?.isNotEmpty ?? false;
    final dockVisible = MediaQuery.viewInsetsOf(context).bottom == 0;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    void navigate(String path) {
      if (path != widget.state.uri.toString() || (search && hasQuery)) {
        context.go(path);
      } else if (home) {
        setState(() {
          _miniCollapsed = false;
          _scrollTravel = 0;
          _scrollDirection = ScrollDirection.idle;
        });
        for (final position in _homeScroll.positions.toList()) {
          position.animateTo(position.minScrollExtent,
            duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
        }
      }
    }

    return ValueListenableBuilder(
      valueListenable: RetainedPlayer.instance.available,
      builder: (context, retained, _) {
      final miniVisible = retained != null && dockVisible;
      final collapsed = miniVisible && _miniCollapsed;
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
                  location: widget.state.uri.toString(),
                  onNavigate: navigate,
                  child: home ? PrimaryScrollController(controller: _homeScroll, child: widget.child) : widget.child,
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
                                  ? bottomInset + IosNavigationDock.clearance + (miniVisible && !collapsed ? 64 : 0)
                                  : 0,
                            ),
                            child: widget.child,
                          ),
                    ),
                    if (dockVisible)
                      Positioned(
                        left: 12, right: 12, bottom: bottomInset + 8,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.bottomCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0, .14),
                                      end: Offset.zero).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: collapsed
                                  ? Row(key: const ValueKey('compact-dock'), children: [
                                      _compactDockAction(selectedDestination.icon),
                                      const SizedBox(width: 8),
                                      Expanded(child: RetainedPlayerButton(
                                        media: retained!, mobile: true, collapsed: true)),
                                      const SizedBox(width: 8),
                                      _compactDockAction(DockDestination.search.icon),
                                    ])
                                  : Column(key: const ValueKey('expanded-dock'),
                                      mainAxisSize: MainAxisSize.min, children: [
                                        if (miniVisible) ...[
                                          Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: RetainedPlayerButton(media: retained!, mobile: true)),
                                          const SizedBox(height: 6),
                                        ],
                                        IosNavigationDock(
                                          selectedDestination: selectedDestination,
                                          onSelected: (destination) => navigate(destination.path),
                                        ),
                                      ]),
                              ),
                            ),
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
