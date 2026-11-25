import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:flutter/material.dart' as material;
import 'dart:ui' show ImageFilter;
import 'package:petal/pages/player/player_theme.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Desktop menus share the same frosted popover styling as PetalContextMenu.
class PlayerMenuAction {
  final String label;
  final Widget? icon;
  final VoidCallback onPressed;
  const PlayerMenuAction({required this.label, this.icon, required this.onPressed});
}

Offset playerMenuAnchor(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
  }
  return MediaQuery.sizeOf(context).center(Offset.zero);
}

Future<void> showPlayerMenu(BuildContext context, {
  required String title, required List<PlayerMenuAction> actions,
  Offset? anchor,
}) async {
  if (TvLayout.isCompact(context)) {
    await glass.showGlassActionSheet<void>(context: context, title: title,
      actions: [for (final action in actions)
        glass.GlassActionSheetAction(label: action.label, icon: action.icon,
          onPressed: action.onPressed)]);
    return;
  }
  final group = Object();
  await showOverlay<void>(context,
    PopoverConfiguration(
      position: anchor ?? playerMenuAnchor(context),
      alignment: Alignment.topLeft, anchorAlignment: Alignment.topRight,
      margin: const EdgeInsets.all(8), follow: false, modal: true,
      dismissBackdropFocus: false, regionGroupId: group,
    ),
    adaptive: false,
    builder: (context) => MenuGroup(
      direction: Axis.vertical, regionGroupId: group,
      onDismissed: () => closeOverlay(context),
      itemPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      children: [
        MenuLabel(child: Text(title)),
        const MenuDivider(),
        for (final action in actions)
          MenuButton(
            child: Row(spacing: 8, children: [
              SizedBox(width: 20, child: action.icon),
              Expanded(child: Text(action.label)),
            ]),
            onPressed: (_) => action.onPressed(),
          ),
      ],
      builder: (context, children) {
        final colors = Theme.of(context).colorScheme;
        return ConstrainedBox(
          constraints: BoxConstraints(minWidth: 220, maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * .75),
          child: SingleChildScrollView(child: MenuPopup(
            theme: MenuPopupTheme(borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(6), fillColor: colors.popover,
              borderColor: colors.foreground.withValues(alpha: .12),
              surfaceBlur: 20, surfaceOpacity: .86),
            children: children,
          )),
        );
      },
    ),
  ).future;
}

/// Compact screens use sheets; desktop uses an anchored, non-dimming panel.
class PlayerPanelClose extends InheritedWidget {
  final void Function(Object?) close;
  const PlayerPanelClose({super.key, required this.close, required super.child});
  @override
  bool updateShouldNotify(PlayerPanelClose oldWidget) => close != oldWidget.close;
}

void closePlayerPanel(BuildContext context, [Object? result]) {
  final scope = context.dependOnInheritedWidgetOfExactType<PlayerPanelClose>();
  if (scope != null) {
    scope.close(result);
  } else {
    Navigator.of(context).pop(result);
  }
}

Future<T?> showPlayerGlassPanel<T>(BuildContext context, {
  required String title, required WidgetBuilder builder, double maxWidth = 440,
  Offset? anchor,
}) {
  final compact = TvLayout.isCompact(context);
  if (!compact) {
    T? result;
    await showOverlay<void>(context,
      PopoverConfiguration(
        position: anchor ?? playerMenuAnchor(context),
        alignment: Alignment.topLeft, anchorAlignment: Alignment.topRight,
        margin: const EdgeInsets.all(8), follow: false, modal: true,
        dismissBackdropFocus: false,
      ),
      adaptive: false,
      builder: (overlayContext) => PlayerTheme(
        child: material.Material(type: material.MaterialType.transparency,
          child: PlayerPanelClose(
            close: (value) {
              result = value as T?;
              closeOverlay(overlayContext);
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: MediaQuery.sizeOf(overlayContext).height * .75),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(overlayContext).colorScheme.popover.withValues(alpha: .90),
                      border: Border.all(color: Colors.white.withValues(alpha: .12)),
                      borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.all(12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                        PetalButton.ghost(onPressed: () => closeOverlay(overlayContext),
                          child: const Icon(LucideIcons.x, size: 16)),
                      ]),
                      const SizedBox(height: 8),
                      Flexible(child: SingleChildScrollView(child: Builder(builder: builder))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).future;
    return result;
  }
  return material.showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close $title',
    barrierColor: const Color(0x66000000),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, _) => PlayerTheme(
      child: material.Material(
        type: material.MaterialType.transparency,
        child: SafeArea(child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 24),
          child: Align(
            alignment: compact ? Alignment.bottomCenter : Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: const Color(0xE3222226),
                    padding: const EdgeInsets.all(18),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(child: Text(title, style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
                        PetalButton.ghost(onPressed: () => Navigator.of(context).pop(),
                          child: const Icon(LucideIcons.x, color: Colors.white, size: 19)),
                      ]),
                      const SizedBox(height: 14),
                      Flexible(child: SingleChildScrollView(child: Builder(builder: builder))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        )),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return compact ? SlideTransition(
        position: eased.drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
        child: child) : FadeTransition(opacity: eased, child: child);
    },
  );
}
