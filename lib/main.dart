import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  Api.initApi();

  runApp(PetalApp());
}

class PetalApp extends StatefulWidget {
  const PetalApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<PetalApp> createState() => _PetalState();
}

class _PetalState extends State<PetalApp> {
  // ThemeMode? themeMode = ThemeMode.dark;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Petal', theme: ThemeData.dark(), home: Navigation());
  }
}
