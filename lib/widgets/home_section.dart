import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class HomeSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyOpen;

  const HomeSection({super.key, required this.title, required this.child, this.initiallyOpen = true});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 16.sp, fontWeight: FontWeight.w600);
    return Column(
      children: [
        Button(
          style: ButtonVariance.ghost,
          onPressed: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: style, textAlign: TextAlign.left)),
                Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16),
              ],
            ),
          ),
        ),
        if (_open) widget.child,
      ],
    );
  }
}
