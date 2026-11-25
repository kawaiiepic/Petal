import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.editorial = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool editorial;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final style = TextStyle(
      fontSize: editorial
          ? 21
          : Device.screenType == ScreenType.desktop
          ? 12.sp
          : 16.sp,
      fontWeight: editorial ? FontWeight.w700 : FontWeight.w600,
    );
    return Padding(
      padding:
          padding ??
          (editorial
              ? const EdgeInsets.only(top: 8, bottom: 18)
              : EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 4 : 8,
                )),
      child: Column(
        spacing: compact ? 4 : 8,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: editorial ? 20 : 8,
              vertical: editorial ? 10 : 6,
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: style),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
