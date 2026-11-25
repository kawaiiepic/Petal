import 'package:flutter/foundation.dart' show TargetPlatform, listEquals;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// An iOS-style frosted menu anchored to the click or long press.
/// Uses Petal's existing menu items so focus, shortcuts and actions still work.
class PetalContextMenu extends StatefulWidget {
  const PetalContextMenu({super.key, required this.items, required this.child});

  final List<MenuItem> items;
  final Widget child;

  @override
  State<PetalContextMenu> createState() => _PetalContextMenuState();
}

class _PetalContextMenuState extends State<PetalContextMenu> {
  late final _items = ValueNotifier(widget.items);
  bool _open = false;

  @override
  void didUpdateWidget(covariant PetalContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items)) {
      // The popup lives in the overlay, outside this widget's build subtree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _items.value = widget.items;
      });
    }
  }

  @override
  void dispose() {
    _items.dispose();
    super.dispose();
  }

  Future<void> _show(Offset position) async {
    if (_open || widget.items.isEmpty) return;
    _open = true;
    final group = Object();
    try {
      await showOverlay<void>(
        context,
        PopoverConfiguration(
          position: position + const Offset(6, 0),
          alignment: Alignment.topLeft,
          anchorAlignment: Alignment.topRight,
          margin: const EdgeInsets.all(8),
          follow: false,
          modal: true,
          dismissBackdropFocus: false,
          regionGroupId: group,
        ),
        adaptive: false,
        builder: (context) => ValueListenableBuilder(
          valueListenable: _items,
          builder: (context, items, _) => MenuGroup(
            direction: Axis.vertical,
            regionGroupId: group,
            onDismissed: () => closeOverlay(context),
            itemPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            children: items,
            builder: (context, children) {
              final colors = Theme.of(context).colorScheme;
              return ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220),
                child: MenuPopup(
                  theme: MenuPopupTheme(
                    borderRadius: BorderRadius.circular(22),
                    padding: const EdgeInsets.all(6),
                    fillColor: colors.popover,
                    borderColor: colors.foreground.withValues(alpha: 0.12),
                    surfaceBlur: 20,
                    surfaceOpacity: 0.86,
                  ),
                  children: children,
                ),
              );
            },
          ),
        ),
      ).future;
    } finally {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return widget.child;
    final touch = switch (Theme.of(context).platform) {
      TargetPlatform.iOS ||
      TargetPlatform.android ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (details) => _show(details.globalPosition),
      onLongPressStart: touch
          ? (details) => _show(details.globalPosition)
          : null,
      child: widget.child,
    );
  }
}
