import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/navigation/navigation.dart';
import 'package:blssmpetal/pages/offline.dart';
import 'package:blssmpetal/pages/trakt/traktlogin.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(PetalApp());
}

class PetalApp extends StatefulWidget {
  const PetalApp({super.key});

  @override
  State<PetalApp> createState() => _PetalState();
}

class _PetalState extends State<PetalApp> {
  @override
  void initState() {
    super.initState();
    Api.initApi();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.system,
    showPerformanceOverlay: true,
    home: ValueListenableBuilder(
      valueListenable: Api.healthy,
      builder: (context, healthy, child) {
        if (!healthy) {
          return Offline();
        } else {
          return ValueListenableBuilder<bool>(
            valueListenable: TraktApi.validSession,
            builder: (_, validSession, _) {
              if (!validSession) return TraktLoginPage();

              return const Navigation();
            },
          );
        }
      },
    ),
  );
}
