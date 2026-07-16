import 'package:collection/collection.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Navigation extends StatelessWidget {
  // no longer needs to be Stateful for this purpose
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

    return Scaffold(
      headers: [
        SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [SvgPicture.asset('assets/images/logo-clean.svg', height: 30), Search(), Icon(Icons.av_timer_sharp)],
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
