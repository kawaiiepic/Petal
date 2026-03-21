import 'package:blssmpetal/navigation/profile.dart';
import 'package:blssmpetal/pages/addons.dart';
import 'package:blssmpetal/pages/dashboard/dashboard.dart';
import 'package:blssmpetal/pages/settings.dart';
import 'package:flutter/material.dart';

class Rail extends StatefulWidget {
  final ValueNotifier<int> selectedIndex;

  const Rail({super.key, required this.selectedIndex});

  @override
  State<Rail> createState() => _RailState();
}

class _RailState extends State<Rail> {
  late final Widget _dashboard;
  late final Widget _addons;
  late final Widget _settings;

  @override
  void initState() {
    super.initState();
    _dashboard = Dashboard();
    _addons = Addons();
    _settings = Settings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavigationRail(
              labelType: NavigationRailLabelType.all,
              groupAlignment: -1,
              onDestinationSelected: (int index) {
                setState(() {
                  widget.selectedIndex.value = index;
                });
              },
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.extension_outlined), selectedIcon: Icon(Icons.extension), label: Text('Addons')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
              ],
              leading: const Profile(),
              selectedIndex: widget.selectedIndex.value,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            _page(),
          ],
        ),
      ),
    );
  }

  Widget _page() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            IndexedStack(index: widget.selectedIndex.value, children: [_dashboard, _addons, _settings]),
          ],
        ),
      ),
    );
  }
}
