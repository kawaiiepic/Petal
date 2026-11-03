import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CastFallbackAvatar extends StatelessWidget {
  final IconData icon;

  const CastFallbackAvatar({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.38)),
    );
  }
}
