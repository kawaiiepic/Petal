import 'dart:convert';

import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/trakt_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/api/trakt/trakt_sync.dart';
import 'package:blssmpetal/navigation/navigation.dart';
import 'package:blssmpetal/pages/offline.dart';
import 'package:blssmpetal/pages/trakt/traktlogin.dart';
import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:media_kit/media_kit.dart';
import 'package:http/http.dart' as http;

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
        valueListenable: TraktApi.validSession,
        builder: (context, session, child) {
          if (!session) {
            return TraktLoginPage();
          } else {
            return ValueListenableBuilder<bool>(
              valueListenable: Api.healthy,
              builder: (_, healthy, _) {
                if (!healthy) return Offline();

                return const Navigation();
              },
            );
          }
        },
      ),
    );
  }
}
