import 'dart:ui';

import 'package:blssmpetal/navigation/bar.dart';
import 'package:blssmpetal/navigation/rail.dart';
import 'package:flutter/material.dart';

class Navigation extends StatelessWidget {
  const Navigation({super.key});

  @override
  Widget build(BuildContext context) {
    var display = PlatformDispatcher.instance.views.first.display;
    if (display.size.shortestSide / display.devicePixelRatio > 600) {
      return Rail();
    } else {
      return Bar();
    }
  }
}