import 'dart:ui';

import 'package:blssmpetal/navigation/bar.dart';
import 'package:blssmpetal/navigation/rail.dart';
import 'package:flutter/material.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<StatefulWidget> createState() => _Navigation();
}

class _Navigation extends State<Navigation> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    var display = PlatformDispatcher.instance.views.first.display;
    if (display.size.shortestSide / display.devicePixelRatio > 600) {
      return Rail(selectedIndex: _selectedIndex,);
    } else {
      return Bar();
    }
  }
}
