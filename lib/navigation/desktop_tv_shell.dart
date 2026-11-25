import 'package:petal/navigation/desktop_media_tabs.dart';
import 'package:petal/api/retained_player.dart';
import 'package:petal/navigation/retained_player_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/navigation/user_profile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Desktop browsing frame. The route content scrolls independently of the sidebar.
class DesktopTvShell extends StatelessWidget {
  const DesktopTvShell({
    super.key,
    required this.location,
    required this.onNavigate,
    required this.child,
  });

  final String location;
  final ValueChanged<String> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.15,
              colors: [
                dark ? const Color(0xFF263342) : const Color(0xFFDCE8F6),
                colors.background,
              ],
            ),
          ),
        ),
        Positioned.fill(left: tvDesktopSidebarWidth, child: child),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: tvDesktopSidebarWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const glass.GlassContainer(
                  useOwnLayer: true,
                  shape: glass.LiquidRoundedSuperellipse(borderRadius: 18),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          primary: false,
                          padding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                              child: Row(
                                spacing: 8,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/logo-clean.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const Text(
                                    'Petal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _destination(
                              context,
                              '/search',
                              'Search',
                              LucideIcons.search,
                            ),
                            const SizedBox(height: 14),
                            _destination(
                              context,
                              '/',
                              'Home',
                              LucideIcons.house,
                            ),
                            DesktopMediaTabsView(location: location, onNavigate: onNavigate),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 18, 8, 4),
                              child: Text(
                                'Library',
                                style: TextStyle(
                                  color: colors.mutedForeground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _destination(
                              context,
                              '/collection',
                              'Collection',
                              LucideIcons.library,
                            ),
                            _destination(
                              context,
                              '/history',
                              'History',
                              LucideIcons.history,
                            ),
                            _destination(
                              context,
                              '/downloads',
                              'Downloads',
                              LucideIcons.download,
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder(valueListenable: RetainedPlayer.instance.available,
                        builder: (context, media, _) => media == null ? const SizedBox.shrink() :
                          Padding(padding: const EdgeInsets.only(bottom: 8),
                            child: RetainedPlayerButton(media: media, mobile: false))),
                      const UserProfile(horizontal: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _destination(
    BuildContext context,
    String path,
    String label,
    IconData icon,
  ) {
    final selected = Uri.parse(location).path == path;
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? Colors.white : colors.foreground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: glass.GlassButton.custom(
        useOwnLayer: true,
        label: label,
        isSelected: selected,
        height: 36,
        shape: const glass.LiquidRoundedSuperellipse(borderRadius: 9),
        style: selected
            ? glass.GlassButtonStyle.prominent
            : glass.GlassButtonStyle.transparent,
        tintColor: selected ? const Color(0xFF0069D9) : null,
        stretch: 0,
        onTap: () => onNavigate(path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            spacing: 9,
            children: [
              Icon(icon, size: 16, color: foreground),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
