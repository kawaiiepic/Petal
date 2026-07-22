import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/trakt/trakt_helper.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:petal/widgets/crop.dart';
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
            children: [
              SvgPicture.asset('assets/images/logo-clean.svg', height: 30),
              Search(),
              FutureBuilder(
                future: TraktApi.profiles(),
                builder: (context, snapshot) {
                  return Builder(
                    builder: (buttonContext) {
                      return Button(
                        style: ButtonVariance.text,
                        onPressed: () {
                          showDropdown(
                            context: buttonContext, // scoped to the button, not the whole page
                            builder: (context) {
                              return DropdownMenu(
                                children: [
                                  MenuLabel(child: Text('My Account')),
                                  MenuDivider(),
                                  MenuButton(
                                    child: Text('Switch Profile'),
                                    onPressed: (context) {
                                      showOverlay(
                                        context,
                                        DialogConfiguration(
                                          builder: (context) {
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('Switch Profile', textAlign: TextAlign.center),
                                                  const SizedBox(height: 20),

                                                  Wrap(
                                                    spacing: 20,
                                                    runSpacing: 20,
                                                    children: snapshot.data!.map((profile) => _ProfileCard(name: profile.name, avatar: Icons.person)).toList(),
                                                    // children: [
                                                    //   _ProfileCard(name: 'Main', avatar: Icons.person, selected: true),
                                                    //   _ProfileCard(name: 'Kids', avatar: Icons.child_care),
                                                    //   _ProfileCard(name: 'Guest', avatar: Icons.person_outline),
                                                    //   _ProfileCard(name: 'Add Profile', avatar: Icons.add),
                                                    // ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  MenuButton(
                                    onPressed: (_) async {
                                      await TraktApi.signOut();

                                      if (context.mounted) context.go('/login');
                                    },
                                    child: const Text('Log out'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: CircleAvatar(child: Icon(Icons.person_2)),
                      );
                    },
                  );
                },
              ),
            ],
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

class _ProfileCard extends StatefulWidget {
  final String name;
  final IconData avatar;
  final bool selected;

  const _ProfileCard({required this.name, required this.avatar, this.selected = false});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool hovering = false;

  Future<void> pickAvatar() async {
    final result = await FilePicker.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      showOverlay(context, DialogConfiguration(builder: (_) => AvatarCropDialog(image: file)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: Button(
        style: ButtonVariance.text,
        onPressed: () {
          if (widget.selected) {
            pickAvatar();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(radius: 35, child: Icon(widget.avatar, size: 35)),

                if (hovering && widget.selected)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.black.withAlpha(220), shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 28),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.name),
                if (widget.selected) ...[const SizedBox(width: 5), const Icon(Icons.check, size: 16)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
