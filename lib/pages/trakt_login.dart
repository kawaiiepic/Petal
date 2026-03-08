import 'package:flutter/material.dart';
import '../api/api.dart';

class TraktLoginPage extends StatefulWidget {
  const TraktLoginPage({super.key});

  @override
  State<TraktLoginPage> createState() => _TraktLoginPageState();
}

class _TraktLoginPageState extends State<TraktLoginPage> {
  bool loading = false;

  void login() async {
    setState(() {
      loading = true;
    });

    // placeholder login logic
    await Future.delayed(const Duration(seconds: 1));

    Api.traktLoggedIn = true;

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login with Trakt to continue',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Login with Trakt'),
            )
          ],
        ),
      ),
    );
  }
}
