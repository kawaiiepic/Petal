import 'package:blssmpetal/navigation/bar.dart';
import 'package:blssmpetal/navigation/rail.dart';
import 'package:flutter/material.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<StatefulWidget> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        Orientation orientation = MediaQuery.of(context).orientation;

        if (orientation == Orientation.landscape) {
          return Rail();
        } else {
          return Bar(); // BottomBar
        }
      },
    );
  }
}
