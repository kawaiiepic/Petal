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
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final episode = widget.media.item.episode;
    return FutureBuilder(future: _metadata, builder: (context, snapshot) {
      final title = snapshot.data?.title ?? 'Resume playback';
      return glass.GlassContainer(
        useOwnLayer: true,
        shape: glass.LiquidRoundedSuperellipse(borderRadius: widget.mobile ? 29 : 18),
        clipBehavior: Clip.antiAlias,
        child: Container(height: widget.mobile ? 58 : null,
          padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 7 : 8, vertical: 6),
          child: Row(children: [
            Expanded(child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: _open,
              child: Row(children: [
                if (widget.mobile) ...[
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: SizedBox(width: widget.collapsed ? 34 : 42, height: widget.collapsed ? 38 : 42,
                      child: MediaArtwork(imageUrl: snapshot.data?.art))),
                  SizedBox(width: widget.collapsed ? 6 : 10),
                ],
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.foreground, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(episode == null ? 'Paused · Resume' : 'S${episode.seasonNumber} · E${episode.episodeNumber} · Paused',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.mutedForeground, fontSize: 11)),
                  ])),
              ]),
            )),
            glass.GlassButton.custom(useOwnLayer: true,
              shape: const glass.LiquidRoundedRectangle(borderRadius: 20),
              style: glass.GlassButtonStyle.transparent, onTap: _open,
              child: Icon(LucideIcons.play, size: 20, color: colors.foreground)),
            if (!widget.collapsed) glass.GlassButton.custom(useOwnLayer: true,
              shape: const glass.LiquidRoundedRectangle(borderRadius: 20),
              style: glass.GlassButtonStyle.transparent,
              onTap: RetainedPlayer.instance.dismiss,
              child: Icon(LucideIcons.x, size: 15, color: colors.mutedForeground)),
          ])),
      );
    });
  }
}
