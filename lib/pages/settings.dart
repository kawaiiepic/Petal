import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple persisted theme controller. Call `AppTheme.load()` once at
/// startup (before runApp), then wire `AppTheme.mode` into your
/// MaterialApp's `themeMode:` — see the note at the bottom of this file.
class AppTheme {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _prefsKey = 'theme_mode';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    mode.value = ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system);
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.name);
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const _playerPrefsKey = 'external_player';

  String selectedPlayer = "Disabled";
  late final Future<PackageInfo> _packageInfo;
  late final Future<Response> _contributors;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _contributors = get(Uri.parse('https://api.github.com/repos/kawaiiepic/Petal/contributors'));
    _loadSelectedPlayer();
  }

  Future<void> _loadSelectedPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_playerPrefsKey);
    if (stored != null && mounted) {
      setState(() => selectedPlayer = stored);
    }
  }

  Future<void> _setSelectedPlayer(String value) async {
    setState(() => selectedPlayer = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerPrefsKey, value);
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image cache cleared')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Settings & About")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          spacing: 8,
          children: [
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
                    _setSelectedPlayer(value);
                  },
                ),
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.mode,
                builder: (context, mode, _) => ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text("Theme"),
                  subtitle: const Text("Choose light, dark, or system"),
                  trailing: DropdownButton<ThemeMode>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
                      DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      AppTheme.set(value);
                    },
                  ),
                ),
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text("About"),
                subtitle: FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, infoSnapshot) {
                    if (infoSnapshot.hasError) {
                      return const Text("Couldn't load app info");
                    }

                    switch (infoSnapshot.connectionState) {
                      case ConnectionState.active:
                      case ConnectionState.done:
                        {
                          final data = infoSnapshot.data;
                          if (data == null) return const Text("Couldn't load app info");

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Text("App: ${data.appName}"),
                              Text("Version: ${data.version}+${data.buildNumber}"),
                              FutureBuilder<Response>(
                                future: _contributors,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Text("Couldn't load contributors");
                                  }
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  final response = snapshot.data!;
                                  if (response.statusCode != 200) {
                                    return const Text("Couldn't load contributors");
                                  }

                                  final List<dynamic> contributorsJson = jsonDecode(response.body);

                                  final List<Widget> contributorChips = contributorsJson
                                      .map(
                                        (entry) => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          spacing: 8,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadiusGeometry.circular(20),
                                              child: Image.network(entry['avatar_url'], width: 20, height: 20),
                                            ),
                                            Text(entry["login"]),
                                            Text("(${entry["contributions"]})"),
                                          ],
                                        ),
                                      )
                                      .toList();

                                  return Row(
                                    spacing: 8,
                                    children: [
                                      const Text("Contributors: "),
                                      Wrap(spacing: 8, children: contributorChips),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        }
                      case _:
                        return const SizedBox();
                    }
                  },
                ),
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.new_releases_outlined),
                title: const Text("What's New"),
                subtitle: const Text("View the changelog on GitHub"),
                onTap: () => _launchUrl("https://github.com/kawaiiepic/Petal/releases"),
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text("Report a Problem"),
                subtitle: const Text("File an issue or send feedback"),
                onTap: () => _launchUrl("https://github.com/kawaiiepic/Petal/issues/new"),
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text("Clear Image Cache"),
                subtitle: const Text("Free up space used by cached thumbnails"),
                onTap: _clearImageCache,
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text("Licenses"),
                subtitle: const Text("Open source licenses"),
                onTap: () async {
                  final info = await _packageInfo;
                  if (!context.mounted) return;
                  showLicensePage(context: context, applicationName: info.appName, applicationVersion: "${info.version}+${info.buildNumber}");
                },
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
    ),
  );
}
