import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:blssmpetal/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TraktLoginPage extends StatefulWidget {
  const TraktLoginPage({super.key});

  @override
  State createState() => _TraktLoginPageState();
}

class _TraktLoginPageState extends State<TraktLoginPage> {
  String? _userCode;
  String? _verificationUrl;
  bool _loading = false;
  bool _waiting = false;

  Future<void> startAuth() async {
    setState(() => _loading = true);

    final data = await TraktAuth.requestDeviceCode();
    setState(() {
      _userCode = data['user_code'];
      _verificationUrl = data['verification_url'];
      _loading = false;
      _waiting = true;
    });

    if (await canLaunchUrl(Uri.parse(_verificationUrl!))) {
      await launchUrl(Uri.parse(_verificationUrl!));
    }

    await TraktAuth.pollForAccessToken(data['device_code'], data['interval'], data['expires_in']);
    Api.traktLoggedIn = true;
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Petal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Connect your Trakt account to continue.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),

              const SizedBox(height: 36),

              if (_userCode != null) ...[
                // Code display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Text(_userCode!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 8)),
                      const SizedBox(height: 6),
                      Text('Enter this code at trakt.tv/activate', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Copy button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _userCode!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 2)));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy code'),
                  ),
                ),

                const SizedBox(height: 12),

                // Open browser button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_verificationUrl!)),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Open trakt.tv/activate'),
                  ),
                ),

                const SizedBox(height: 20),

                // Waiting indicator
                if (_waiting)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                      const SizedBox(width: 10),
                      Text('Waiting for authorization...', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _loading ? null : startAuth,
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Connect with Trakt'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}