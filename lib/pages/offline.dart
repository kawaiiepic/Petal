import 'package:flutter/material.dart';

class Offline extends StatelessWidget {
  const Offline({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Server reconnecting...")));
  }
}
