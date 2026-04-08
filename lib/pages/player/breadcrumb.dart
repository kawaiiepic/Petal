import 'package:flutter/material.dart';

class Breadcrumb extends StatefulWidget {
  const Breadcrumb({super.key});

  @override
  State<StatefulWidget> createState() => _BreadcrumbState();
}

class _BreadcrumbState extends State {
  late final ValueNotifier<String?> _breadcrumb = ValueNotifier(null);

    void showBreadcrumb(String message, {Duration duration = const Duration(seconds: 2)}) {
    _breadcrumb.value = message;
    Future.delayed(duration, () {
      _breadcrumb.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _breadcrumb,
      builder: (context, msg, _) {
        if (msg == null) return const SizedBox.shrink();
        return Center(
          heightFactor: 20,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        );
      },
    );
  }
}
