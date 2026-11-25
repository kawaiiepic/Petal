import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/external_player.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:petal/widgets/ios/ios_controls.dart';

class StreamTile extends StatelessWidget {
  final StreamItem stream;
  final int tmdbId;
  final Episode? episode;
  final bool download;
  final String title;
  final String? mediaTitle;
  final String? episodeTitle;

  const StreamTile({
    super.key,
    required this.stream,
    required this.tmdbId,
    this.episode,
    this.download = false,
    this.title = '',
    this.mediaTitle,
    this.episodeTitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final logo = stream.addon.manifest?['logo'];
    final fallback = Icon(stream.external ? LucideIcons.externalLink : LucideIcons.server,
      size: 22, color: colors.mutedForeground);
    return PetalButton.card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: 42,
              child: logo is String && logo.isNotEmpty
                  ? CachedNetworkImage(imageUrl: logo, fit: BoxFit.contain,
                      errorWidget: (_, _, _) => fallback,
                      placeholder: (_, _) => fallback)
                  : fallback,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stream.name.trim().isEmpty ? 'Source' : stream.name,
                style: TextStyle(color: colors.foreground, fontSize: 14,
                  fontWeight: FontWeight.w600)),
              if (stream.title.trim().isNotEmpty && stream.title != stream.name) ...[
                const SizedBox(height: 4),
                Text(stream.title, style: TextStyle(color: colors.mutedForeground,
                  fontSize: 12, height: 1.4)),
              ],
            ],
          )),
          const SizedBox(width: 10),
          Icon(download ? LucideIcons.download : stream.external
              ? LucideIcons.externalLink : LucideIcons.play,
            size: 18, color: colors.foreground),
        ],
      ),
      onPressed: () async {
        if (download) {
          try {
            await DownloadManager.enqueueStream(
              stream: stream,
              tmdbId: tmdbId,
              title: title.isEmpty ? stream.title : title,
              season: episode?.seasonNumber,
              episode: episode?.episodeNumber,
              mediaTitle: mediaTitle,
              episodeTitle: episodeTitle,
            );
            if (context.mounted) context.push('/downloads');
          } catch (_) {
            if (context.mounted) {
              showToast(
                context: context,
                builder: (context, overlay) =>
                    const Text('This source cannot be saved on device.'),
              );
            }
          }
          return;
        }
        if (await ExternalPlayer.openTracked(
          stream: stream,
          mediaId: tmdbId,
          episode: episode,
          label: mediaTitle == null
              ? title
              : '$mediaTitle${episodeTitle == null ? '' : ' — $episodeTitle'}',
        ))
          return;
        if (stream.external) return;
        if (!context.mounted) return;
        if (episode != null) {
          context.push(
            '/player?media=$tmdbId&s=${episode?.seasonNumber}&e=${episode?.episodeNumber}',
            extra: stream,
          );
        } else {
          context.push('/player?media=$tmdbId', extra: stream);
        }
      },
    );
  }
}
