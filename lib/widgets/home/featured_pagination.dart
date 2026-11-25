import 'package:petal/widgets/home/featured_autoplay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Compact pagination dots with an expanded indicator for autoplay progress.
class FeaturedPagination extends StatelessWidget {
  const FeaturedPagination({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int count;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final progress = FeaturedAutoplay.progressOf(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < count; index++)
            Semantics(
              button: true,
              selected: selectedIndex == index,
              label: 'Featured title ${index + 1} of $count',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: selectedIndex == index ? 34 : 16,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: selectedIndex == index ? 26 : 7,
                      height: 7,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Color(0x66FFFFFF),
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      child: selectedIndex == index
                          ? AnimatedBuilder(
                              animation: progress,
                              builder: (context, _) => Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: FractionallySizedBox(
                                  widthFactor: .25 + .75 * progress.value,
                                  heightFactor: 1,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
