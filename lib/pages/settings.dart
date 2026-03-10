import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/pages/trakt/traktlogin.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool traktConnected = TraktApi.accessToken.isNotEmpty;

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _connectTrakt() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TraktLoginPage()));
    setState(() {
      traktConnected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings & About")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connect Trakt
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Connect Trakt"),
              subtitle: Text(traktConnected ? "Connected" : "Sync your watchlist and history"),
              trailing: ElevatedButton(onPressed: traktConnected ? null : _connectTrakt, child: Text(traktConnected ? "Connected" : "Connect")),
            ),
          ),

          const SizedBox(height: 16),

          // About
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [Text("App: Petal"), Text("Version: 1.0.0"), Text("Contributors: Mia")],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Community Links
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.chat),
              title: const Text("Community"),
              subtitle: const Text("Join our Discord or GitHub"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.discord_rounded), onPressed: () => _launchUrl("#")),
                  IconButton(icon: const Icon(Icons.code_rounded), onPressed: () => _launchUrl("#")),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.support),
              title: const Text("Support"),
              subtitle: const Text("Report issues or contact us"),
              trailing: ElevatedButton(onPressed: () => _launchUrl("#"), child: const Text("Contact")),
            ),
          ),

          const SizedBox(height: 16),

          // Donate
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text("Donate"),
              subtitle: const Text("Support development of the app"),
              trailing: ElevatedButton(onPressed: () => _launchUrl("#"), child: const Text("Donate")),
            ),
          ),
        ],
      ),
    );
  }
}
