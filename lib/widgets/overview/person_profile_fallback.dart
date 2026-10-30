import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PersonProfileFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 170,
      color: Colors.white.withOpacity(0.12),
      child: Icon(LucideIcons.user, color: Colors.white.withOpacity(0.38)),
    );
  }
}
