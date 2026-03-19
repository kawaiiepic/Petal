import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String selectedPlayer = "Disabled";
  late final Future _packageInfo;
  late final Future _contributors;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _contributors = get(Uri.parse('https://api.github.com/repos/kawaiiepic/Petal/contributors'));
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Settings & About")),
    body: Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        spacing: 8,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Connect Trakt"),
              subtitle: Text("Connected"),
              trailing: ElevatedButton(onPressed: null, child: Text("Connected")),
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text("External Player"),
              subtitle: const Text("Choose your preferred player"),
              trailing: DropdownButton<String>(
                value: selectedPlayer,
                items: ["Disabled", "Outplayer", "MX Player"].map((player) {
                  return DropdownMenuItem(value: player, child: Text(player));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedPlayer = value;
                  });
                },
              ),
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              subtitle: FutureBuilder(
                future: _packageInfo,
                builder: (context, infoSnapshot) {
                  switch (infoSnapshot.connectionState) {
                    case ConnectionState.active:
                    case ConnectionState.done:
                      {
                        final PackageInfo data = infoSnapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Text("App: ${data.appName}"),
                            Text("Version: ${data.version}+${data.buildNumber}"),
                            FutureBuilder(
                              future: _contributors,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final List<dynamic> data = jsonDecode((snapshot.data as Response).body);

                                  final List<Widget> strings = data
                                      .map(
                                        (map) => Row(
                                          spacing: 8,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadiusGeometry.circular(20),
                                              child: Image.network(map['avatar_url'], width: 20, height: 20),
                                            ),
                                            Text(map["login"]),
                                            Text("(${map["contributions"]})"),
                                          ],
                                        ),
                                      )
                                      .toList();

                                  return Row(spacing: 8, children: [Text("Contributors: "), ...strings]);
                                }
                                return Text('');
                              },
                            ),
                          ],
                        );
                      }
                    case _:
                      return SizedBox();
                  }
                },
              ),
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.chat),
              title: const Text("Community"),
              subtitle: const Text("Join our Discord or GitHub"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.discord_rounded), onPressed: () => _launchUrl("https://discord.com/")),
                  IconButton(icon: const Icon(Icons.code_rounded), onPressed: () => _launchUrl("https://github.com/kawaiiepic/Petal")),
                ],
              ),
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text("Donate"),
              subtitle: const Text("Support development of the app"),
              trailing: ElevatedButton(onPressed: () => _launchUrl("https://ko-fi.com/"), child: const Text("Donate")),
            ),
          ),
        ],
      ),
    ),
  );
}
