import 'package:dio/dio.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final usernameController = TextEditingController();
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
      print("Trying login with email: $email and password: $password");
      final response = await BackendApi.dio.post("${Api.ServerUrl}/users/login", data: {"email": email, "password": password});
      print(response.data);
      if (response.data["success"] != true) {
        setState(() {
          error = response.data["error"];
        });
        throw Exception("Invalid credentials");
      }
      if (mounted) {
        BackendApi.verifySession();
        context.go('/');
      }
    } on DioException catch (e) {
      print(e.response?.statusCode); // 400
      print(e.response?.data); // validation message
      print(e.requestOptions.headers);
      print(e.requestOptions.data);

      setState(() {
        final d = e.response?.data;
        error = d is Map ? (d['errors']?[0]?['message'] ?? d['error'] ?? d['message'])?.toString() : e.message;
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
      final username = usernameController.text;
      final email = emailController.text;
      final password = passwordController.text;
      final token = registrationTokenController.text;
      final response = await BackendApi.dio.post(
        "${Api.ServerUrl}/users/register",
        data: {"username": username, "email": email, "full_name": username, "password": password, "token": token},
      );

      print(response.data);

      if (response.data["status"] == "already-exist") throw Exception("Account already exist");
      if (response.data["success"] != true) {
        throw Exception("Registration failed");
      }
      if (mounted) {
        BackendApi.verifySession();
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(register ? "Register" : "Login", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (register) ...[
                  TextField(
                    controller: usernameController,
                    placeholder: Text('Username'),
                    onSubmitted: (value) => loading ? null : (register ? handleRegister() : handleLogin()),
                    // decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: emailController,
                  placeholder: Text('Email'),
                  onSubmitted: (value) => loading ? null : (register ? handleRegister() : handleLogin()),
                  // decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  placeholder: Text('Password'),
                  onSubmitted: (value) => loading ? null : (register ? handleRegister() : handleLogin()),
                  features: [
                    InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
                    InputFeature.passwordToggle(mode: PasswordPeekMode.hold),
                  ],
                  // decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                ),
                if (register) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: registrationTokenController,
                    placeholder: Text('Registration Token'),
                    onSubmitted: (value) => loading ? null : (register ? handleRegister() : handleLogin()),
                    features: [InputFeature.passwordToggle(mode: PasswordPeekMode.hold)],
                    // decoration: const InputDecoration(labelText: "Registration Token", border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 16),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Button.primary(
                    onPressed: loading ? null : (register ? handleRegister : handleLogin),
                    child: loading
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
