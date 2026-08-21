import 'package:collection/collection.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/main.dart';
import 'package:petal/navigation/profile.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class Navigation extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const Navigation({super.key, required this.child, required this.state});

  static final List<_NavItem> _navItems = const [
    _NavItem(key: ValueKey(0), icon: Icons.home_rounded, label: 'Home', route: '/'),
    _NavItem(key: ValueKey(1), icon: Icons.download, label: 'Addons', route: '/addons', popUp: true),
    _NavItem(key: ValueKey(2), icon: Icons.settings, label: 'Settings', route: '/settings', popUp: true),
  ];

  Key _selectedKeyForLocation(String location) {
    // Match the most specific route first (e.g. '/addons' before '/')
    final match = _navItems.where((item) => location == item.route || location.startsWith('${item.route}/')).toList()
      ..sort((a, b) => b.route.length.compareTo(a.route.length)); // longest match wins

    if (match.isNotEmpty) return match.first.key;
    return const ValueKey(0); // fallback to Home
  }

  @override
  Widget build(BuildContext context) {
    final currentSelected = _selectedKeyForLocation(state.uri.path);

    return RefreshTrigger(
      key: PetalApp.refreshTriggerKey,
      onRefresh: () async {
        await BackendCache.fetchContinueWatching();
      },
      child: Scaffold(
        headers: [
          SafeArea(
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(1.w, 0, 1.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // mainAxisSize: MainAxisSize.min,
                children: [SvgPicture.asset('assets/images/logo-clean.svg', height: 30), Search(), UserProfile()],
              ),
            ),
          ),
        ],
        footers: [
          const Divider(),
          NavigationBar(
            alignment: NavigationBarAlignment.spaceAround,
            labelType: NavigationLabelType.none,
            expanded: true,
            selectedKey: currentSelected,
            onSelected: (key) {
              final selectedNavItem = _navItems.firstWhere((i) => i.key == key);
              selectedNavItem.popUp ? context.push(selectedNavItem.route) : context.go(selectedNavItem.route);
            },
            children: _navItems
                .mapIndexed(
                  (i, v) => NavigationItem(
                    key: ValueKey(i),
                    style: const ButtonStyle.muted(density: ButtonDensity.icon),
                    selectedStyle: const ButtonStyle.fixed(density: ButtonDensity.icon),
                    label: Text(v.label),
                    child: Icon(v.icon),
                  ),
                )
                .toList(),
          ),
        ],
        child: child,
      ),
    );
  }
}

class _NavItem {
  final Key key;
  final IconData icon;
  final String label;
  final String route;
  final bool popUp;
  const _NavItem({required this.key, required this.icon, required this.label, required this.route, this.popUp = false});
}
