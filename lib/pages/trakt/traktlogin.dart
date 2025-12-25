import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TraktLoginPage extends StatefulWidget {
  const TraktLoginPage({super.key});

  @override
  _TraktLoginPageState createState() => _TraktLoginPageState();
}

class _TraktLoginPageState extends State<TraktLoginPage> {
  String? _userCode;
  String? _verificationUrl;

  Future<void> startAuth() async {
    final data = await TraktAuth.requestDeviceCode();
    setState(() {
      _userCode = data['user_code'];
      _verificationUrl = data['verification_url'];
    });

    // Open browser for user
    if (await canLaunchUrl(Uri.parse(_verificationUrl!))) {
      await launchUrl(Uri.parse(_verificationUrl!));
    }

    // Polling can be done every `interval` seconds until user completes auth
    final token = await TraktAuth.pollForAccessToken(data['device_code'], data['interval'], data['expires_in']);

    print('Access token: $token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect Trakt")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userCode != null) Text("Enter code: $_userCode"),
            ElevatedButton(onPressed: startAuth, child: Text("Connect Trakt")),
          ],
        ),
      ),
    );
  }
}
