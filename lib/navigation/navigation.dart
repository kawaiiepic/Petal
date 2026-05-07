import 'package:collection/collection.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Navigation extends StatefulWidget {
  final Widget child;

  const Navigation({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _Navigation();
}

class _Navigation extends State<Navigation> {
  final List<_NavItem> _navItems = const [
    _NavItem(key: ValueKey(0), icon: Icons.home_rounded, label: 'Home', route: '/'),
    _NavItem(key: ValueKey(1), icon: Icons.download, label: 'Addons', route: '/addons', popUp: true),
    _NavItem(key: ValueKey(2), icon: Icons.settings, label: 'Settings', route: '/settings', popUp: true),
  ];

  Key? selected = const ValueKey(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SvgPicture.asset('assets/images/logo-clean.svg', height: 50),
          Search()
        ],)

      ],
      footers: [
        const Divider(),
        NavigationBar(
          alignment: NavigationBarAlignment.spaceAround,
          labelType: NavigationLabelType.none,
          expanded: true,
          selectedKey: selected,
          onSelected: (key) {
            setState(() {
              selected = key;
              var selectedNavItem = _navItems.firstWhere((i) => i.key == key);
              selectedNavItem.popUp ? context.push(selectedNavItem.route) : context.go(selectedNavItem.route);
            });
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
      child: widget.child,
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
