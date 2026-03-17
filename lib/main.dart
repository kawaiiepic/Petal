import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/trakt_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/api/trakt/trakt_sync.dart';
import 'package:blssmpetal/navigation/navigation.dart';
import 'package:blssmpetal/pages/offline.dart';
import 'package:blssmpetal/pages/trakt/traktlogin.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await Api.initApi();

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
    return MaterialApp(
      title: 'Petal',
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: ValueListenableBuilder(
        valueListenable: TraktApi.accessToken,
        builder: (context, token, child) {
          if (token == null) {
            return TraktLoginPage();
          } else {
            return ValueListenableBuilder<bool>(
              valueListenable: Api.healthy,
              builder: (_, healthy, _) {
                if (!healthy) return Offline();

                return Navigation();
              },
            );
          }
        },
      ),
      // home: ValueListenableBuilder<bool>(
      //   valueListenable: Api.healthy,
      //   builder: (_, healthy, _) {
      //     if (!healthy) return Offline();

      //     return Navigation();
      //   },
      // ),
    );
  }
}
