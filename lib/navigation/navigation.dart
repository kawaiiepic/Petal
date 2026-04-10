import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Navigation extends StatelessWidget {
  final Widget child;

  const Navigation({super.key, required this.child});

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/'),
    _NavItem(icon: Icons.trending_up_rounded, label: 'Trending', route: '/catalogs'),
    _NavItem(icon: Icons.movie_rounded, label: 'Movies', route: '/anime'),
    _NavItem(icon: Icons.local_fire_department_rounded, label: 'Hot', route: '/trending'),
    _NavItem(icon: Icons.download, label: 'Addons', route: '/addons', popUp: true),
    _NavItem(icon: Icons.settings, label: 'Settings', route: '/settings', popUp: true),
    _NavItem(icon: Icons.search_rounded, label: 'Search', route: '/search', popUp: true),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Derive selected index from current URL
    const routes = ['/', '/catalogs', '/anime', '/trending', '/search'];

    final index = routes.indexOf(location);

    return Scaffold(
      body: Stack(
        children: [
          child,

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Align(
              alignment: AlignmentGeometry.center,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0C0C).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFFDC3232).withOpacity(0.2), width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isActive = i == index;
                    return GestureDetector(
                      onTap: () => item.popUp ? context.push(item.route) : context.go(item.route),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFDC3232).withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(item.icon, size: 20, color: isActive ? const Color(0xFFE05050) : const Color(0xFF7A5A5A)),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on GoRouter {
  Null get routes => null;
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final bool popUp;
  const _NavItem({required this.icon, required this.label, required this.route, this.popUp = false});
}
