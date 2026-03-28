import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool register = false;
  String? error;

  Future<void> handleLogin() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 🔥 Replace with your API call
      await Future.delayed(const Duration(seconds: 2));

      final email = emailController.text;
      final password = passwordController.text;

      final response = await TraktApi.dio.post("${Api.ServerUrl}/login/signin", data: {"email": email, "password": password});

      print(response.data);

      final cookies = await TraktApi.cookieJar.loadForRequest(Uri.parse("${Api.ServerUrl}/login/verify"));

      print("cookies: $cookies");

      if (email != "test" || password != "password") {
        throw Exception("Invalid credentials");
      }

      // ✅ Navigate after login
      if (mounted) {
        Api.loggedIn = true;
        context.go('/');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

                const SizedBox(height: 24),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : handleLogin,
                    child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Login"),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : handleLogin,
                    child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Register"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
