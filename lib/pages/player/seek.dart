import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Seek extends StatefulWidget {
  const Seek({super.key});

  @override
  State<StatefulWidget> createState() => _SeekState();
}

class _SeekState extends State {
  bool showLeftSeek = false;
  bool showRightSeek = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [if (showLeftSeek) _seekOverlay(left: true), if (showRightSeek) _seekOverlay(left: false)]);
  }

  Widget _seekOverlay({required bool left}) {
    return Positioned.fill(
      child: Align(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(40)),
              child: Text(left ? "<< 10s" : "10s >>", style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
        ),
      ),
    );
  }
}
