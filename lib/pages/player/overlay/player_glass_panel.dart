import 'package:flutter/material.dart' as material;
import 'dart:ui' show ImageFilter;
import 'package:petal/pages/player/player_theme.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Adaptive player panel: compact screens slide up, larger screens use a
/// centered floating surface. Keep the video theme independent of the app.
Future<T?> showPlayerGlassPanel<T>(BuildContext context, {
  required String title, required WidgetBuilder builder, double maxWidth = 440,
}) {
  final compact = TvLayout.isCompact(context);
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
