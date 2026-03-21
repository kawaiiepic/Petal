import 'package:flutter/widgets.dart';

class EmptySliver extends StatelessWidget {
  const EmptySliver({super.key});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: SizedBox(height: 50.0), // Adjust height for desired gap size
  );
}
