import 'package:flutter_svg/svg.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // time for one fade direction
    )..repeat(reverse: true); // fade in, then out, then in, forever

    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment.center, radius: 1.2, colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)]),
        ),
        child: Center(
          child: FadeTransition(opacity: _opacity, child: SvgPicture.asset('assets/images/logo-clean.svg', height: 100)),
        ),
      ),
    );
  }
}
