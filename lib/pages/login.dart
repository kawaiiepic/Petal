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
  final registrationTokenController = TextEditingController();

  bool loading = false;
  bool register = false;
  String? error;

  Future<void> handleLogin() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final email = emailController.text;
      final password = passwordController.text;
      final response = await TraktApi.dio.post("${Api.ServerUrl}/login/signin", data: {"email": email, "password": password});
      print(response.data);
      if (response.data["status"] != "success") {
        throw Exception("Invalid credentials");
      }
      if (mounted) {
        TraktApi.authState.setLoggedIn(true);
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

  Future<void> handleRegister() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final email = emailController.text;
      final password = passwordController.text;
      final token = registrationTokenController.text;
      final response = await TraktApi.dio.post("${Api.ServerUrl}/login/register", data: {"email": email, "password": password, "token": token});
      print(response.data);

      if (response.data["status"] == "already-exist") throw Exception("Account already exist");
      if (response.data["status"] != "success") {
        throw Exception("Registration failed");
      }
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
                Text(register ? "Register" : "Login", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                if (register) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: registrationTokenController,
                    decoration: const InputDecoration(labelText: "Registration Token", border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 16),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : (register ? handleRegister : handleLogin),
                    child: loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(register ? "Register" : "Login"),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              register = !register;
                              error = null;
                              registrationTokenController.clear();
                            });
                          },
                    child: Text(register ? "Already have an account? Login" : "No account? Register"),
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
