import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EmptyCollectionRow extends StatelessWidget {
  final String text;
  const EmptyCollectionRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}
