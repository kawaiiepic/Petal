import 'package:blssmpetal/navigation/profile.dart';
import 'package:blssmpetal/pages/addons.dart';
import 'package:blssmpetal/pages/dashboard.dart';
import 'package:blssmpetal/pages/settings.dart';
import 'package:flutter/material.dart';

class Rail extends StatefulWidget {
  const Rail({super.key});

  @override
  State<Rail> createState() => _RailState();
}

class _RailState extends State<Rail> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return navigationRail();
  }

  Widget navigationRail() {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationRail(
            labelType: NavigationRailLabelType.all,
            groupAlignment: 0,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: Text('Addons')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
            leading: Profile(),
            selectedIndex: _selectedIndex,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          page(),
        ],
      ),
    );
  }

  Widget page() {
    return Expanded(
      child: Padding(padding: EdgeInsetsGeometry.all(8), child: [Dashboard(), Addons(), Settings()][_selectedIndex]),
    );
  }
}
