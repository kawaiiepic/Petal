import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/api/retained_player.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class RetainedPlayerButton extends StatefulWidget {
  final RetainedMedia media;
  final bool mobile;
  final bool collapsed;
  const RetainedPlayerButton({super.key, required this.media, required this.mobile,
    this.collapsed = false});
  @override
  State<RetainedPlayerButton> createState() => _RetainedPlayerButtonState();
}

class _RetainedPlayerButtonState extends State<RetainedPlayerButton> {
  late Future<({String title, String? art})> _metadata = _load();
  @override
  void didUpdateWidget(covariant RetainedPlayerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media != widget.media) _metadata = _load();
  }
  Future<({String title, String? art})> _load() async {
    final item = widget.media.item;
    final download = widget.media.source.download;
    try {
      if (item.episode != null) {
        final show = await TMDB.tvShow(item.mediaId);
        return (title: show.name, art: show.posterPath == null ? null :
          'https://image.tmdb.org/t/p/w185${show.posterPath}');
      }
      final movie = await TMDB.movie(item.mediaId);
      return (title: movie.title, art: movie.posterPath == null ? null :
        'https://image.tmdb.org/t/p/w185${movie.posterPath}');
    } catch (_) {
      return (title: download?.displayTitle ?? 'Resume playback', art: null);
    }
  }
  void _open() {
    final retained = RetainedPlayer.instance.resumable;
    if (retained == null) return;
    final item = retained.item;
    final episode = item.episode;
    final uri = Uri(path: '/player', queryParameters: {
      'media': '${item.mediaId}',
      if (episode != null) 's': '${episode.seasonNumber}',
      if (episode != null) 'e': '${episode.episodeNumber}',
      'resume': '1',
    });
    context.push(uri.toString(), extra: retained);
  }
  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true, label: label,
      child: glass.GlassButton.custom(
        useOwnLayer: true, width: 36, height: 36,
        shape: const glass.LiquidOval(),
        style: glass.GlassButtonStyle.transparent,
        onTap: onTap,
        child: Center(child: Icon(icon, size: 20,
          color: Theme.of(context).colorScheme.foreground)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final episode = widget.media.item.episode;
    return FutureBuilder(future: _metadata, builder: (context, snapshot) {
      final title = snapshot.data?.title ?? 'Resume playback';
      final subtitle = episode == null ? 'Paused' :
        'S${episode.seasonNumber} · E${episode.episodeNumber} · Paused';
      Widget artwork(double width, double height) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: width, height: height,
          child: MediaArtwork(imageUrl: snapshot.data?.art)));
      Widget labels(int lines) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Text(title, maxLines: lines, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.foreground, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subtitle, maxLines: widget.mobile ? 1 : 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.mutedForeground, fontSize: 11)),
        ]);
      final play = _action(LucideIcons.play, 'Resume playback', _open);
      final close = _action(LucideIcons.x, 'Dismiss player', RetainedPlayer.instance.dismiss);
      final content = !widget.mobile
        ? Padding(padding: const EdgeInsets.all(10),
            child: Column(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
              GestureDetector(behavior: HitTestBehavior.opaque, onTap: _open,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  artwork(54, 76), const SizedBox(width: 8), Expanded(child: labels(3)),
                ])),
              Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 10,
                children: [play, close]),
            ]))
        : Padding(padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 7 : 8, vertical: 6),
            child: Row(mainAxisSize: widget.collapsed ? MainAxisSize.max : MainAxisSize.min, children: [
              Flexible(fit: widget.collapsed ? FlexFit.tight : FlexFit.loose,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _open,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    artwork(widget.collapsed ? 34 : 42, widget.collapsed ? 38 : 42),
                    SizedBox(width: widget.collapsed ? 6 : 10),
                    Flexible(fit: FlexFit.loose, child: labels(1)),
                  ]))),
              const SizedBox(width: 4), play,
              if (!widget.collapsed) close,
            ]));
      return Align(
        widthFactor: widget.mobile && !widget.collapsed ? 1 : null,
        child: glass.GlassContainer(
          useOwnLayer: true,
          shape: glass.LiquidRoundedSuperellipse(borderRadius: widget.mobile ? 29 : 18),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    });
  }
}
