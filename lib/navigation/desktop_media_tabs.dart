import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/rendering.dart' show SystemMouseCursors;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/ios/ios_context_menu.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DesktopMediaTab {
  final int id;
  final MediaType type;
  final String title;
  const DesktopMediaTab(this.id, this.type, this.title);
  String get key => '${type.name}:$id';
  String get route => '/${type == MediaType.movie ? 'movie' : 'series'}?tmdb=$id';
}

/// In-memory pins, scoped to the active profile. Never written to disk.
abstract final class DesktopMediaTabs {
  static final pinned = ValueNotifier<List<DesktopMediaTab>>(const []);
  static String? _profile;
  static bool _bound = false;

  static void bind() {
    if (_bound) return;
    _bound = true;
    _profile = BackendApi.profileCacheKey;
    BackendApi.authState.addListener(() {
      final next = BackendApi.profileCacheKey;
      if (next == _profile) return;
      _profile = next;
      pinned.value = const [];
    });
  }

  static bool contains(DesktopMediaTab tab) => pinned.value.any((p) => p.key == tab.key);

  static void toggle(DesktopMediaTab tab) {
    bind();
    pinned.value = contains(tab)
      ? pinned.value.where((p) => p.key != tab.key).toList()
      : [...pinned.value, tab];
  }
}

class MediaTabPinButton extends StatelessWidget {
  final int tmdbId;
  final MediaType type;
  final String title;
  const MediaTabPinButton({super.key, required this.tmdbId, required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    final tab = DesktopMediaTab(tmdbId, type, title);
    return ValueListenableBuilder(valueListenable: DesktopMediaTabs.pinned,
      builder: (context, _, _) {
        final pinned = DesktopMediaTabs.contains(tab);
        return _HoverlessPin(
          label: pinned ? 'Unpin media tab' : 'Pin media tab',
          width: 40, height: 40,
          onTap: () => DesktopMediaTabs.toggle(tab),
          child: Stack(fit: StackFit.expand, children: [
            IgnorePointer(child: glass.GlassContainer(
              useOwnLayer: true, shape: const glass.LiquidOval(),
            )),
            Center(child: Icon(LucideIcons.pin, size: 18,
              color: pinned ? Theme.of(context).colorScheme.primary : Colors.white)),
          ]),
        );
      });
  }
}

class DesktopMediaTabsView extends StatefulWidget {
  final String location;
  final ValueChanged<String> onNavigate;
  const DesktopMediaTabsView({super.key, required this.location, required this.onNavigate});
  @override
  State<DesktopMediaTabsView> createState() => _DesktopMediaTabsViewState();
}

class _DesktopMediaTabsViewState extends State<DesktopMediaTabsView> {
  late Future<DesktopMediaTab?> _active;
  @override
  void initState() {
    super.initState();
    DesktopMediaTabs.bind();
    _active = _resolve(widget.location);
  }

  @override
  void didUpdateWidget(covariant DesktopMediaTabsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _active = _resolve(widget.location);
  }

  Future<DesktopMediaTab?> _resolve(String location) async {
    final uri = Uri.parse(location);
    if (uri.path != '/movie' && uri.path != '/series') return null;
    final type = uri.path == '/movie' ? MediaType.movie : MediaType.show;
    try {
      var id = int.tryParse(uri.queryParameters['tmdb'] ?? '');
      final imdb = uri.queryParameters['imdb'];
      if (id == null && imdb != null) {
        final result = await ApiCache.getTmdbSearch(imdb);
        final matches = type == MediaType.movie ? result.movies : result.tv;
        id = matches.firstOrNull?.id;
      }
      if (id == null) return null;
      final existing = DesktopMediaTabs.pinned.value.where((p) =>
        p.id == id && p.type == type).firstOrNull;
      if (existing != null) return existing;
      final title = type == MediaType.movie ? (await TMDB.movie(id)).title :
        (await TMDB.tvShow(id)).name;
      return DesktopMediaTab(id, type, title);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: DesktopMediaTabs.pinned,
    builder: (context, pins, _) => FutureBuilder(
      future: _active,
      builder: (context, snapshot) {
        final active = snapshot.connectionState == ConnectionState.done ? snapshot.data : null;
        final tabs = [...pins, if (active != null && !pins.any((p) => p.key == active.key)) active];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tab in tabs) _tab(context, tab, active?.key == tab.key),
          ]);
      },
    ),
  );

  Widget _tab(BuildContext context, DesktopMediaTab tab, bool selected) {
    final colors = Theme.of(context).colorScheme;
    final pinned = DesktopMediaTabs.contains(tab);
    final foreground = selected ? Colors.white : colors.foreground;
    return Padding(padding: const EdgeInsets.only(left: 8, bottom: 3),
      child: PetalContextMenu(items: [
        MenuButton(leading: const Icon(LucideIcons.pin),
          onPressed: (_) => DesktopMediaTabs.toggle(tab),
          child: Text(pinned ? 'Unpin' : 'Pin')),
        if (selected) MenuButton(child: const Text('Close tab'),
          onPressed: (_) {
            if (pinned) DesktopMediaTabs.toggle(tab);
            widget.onNavigate('/');
          }),
      ], child: Row(children: [
        Expanded(child: glass.GlassButton.custom(
          useOwnLayer: true, label: tab.title, height: 36,
          isSelected: selected,
          shape: const glass.LiquidRoundedSuperellipse(borderRadius: 9),
          style: selected ? glass.GlassButtonStyle.prominent : glass.GlassButtonStyle.transparent,
          tintColor: selected ? const Color(0xFF0069D9) : null,
          onTap: () { if (!selected) widget.onNavigate(tab.route); },
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(spacing: 7, children: [
              Icon(tab.type == MediaType.movie ? LucideIcons.film : LucideIcons.tv, size: 15, color: foreground),
              Expanded(child: Text(tab.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: foreground))),
            ])),
        )),
        _HoverlessPin(
          label: pinned ? 'Unpin ${tab.title}' : 'Pin ${tab.title}',
          width: 28, height: 32,
          onTap: () => DesktopMediaTabs.toggle(tab),
          child: Icon(LucideIcons.pin, size: 14,
            color: pinned ? colors.primary : colors.mutedForeground),
        ),
      ])),
    );
  }
}

class _HoverlessPin extends StatelessWidget {
  const _HoverlessPin({required this.label, required this.width,
    required this.height, required this.onTap, required this.child});
  final String label;
  final double width;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true, label: label,
    child: FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          onTap();
          return null;
        }),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: width, height: height, child: Center(
          child: SizedBox(width: width, height: height, child: Center(child: child)),
        )),
      ),
    ),
  );
}
