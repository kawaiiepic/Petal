import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/external_player.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

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
    return Button.card(
      leading: stream.external
          ? const Icon(RadixIcons.externalLink)
          : CachedNetworkImage(
              imageUrl: stream.addon.manifest?['logo'],
              imageBuilder: (context, imageProvider) => Avatar(
                initials: '',
                provider: imageProvider,
                backgroundColor: Colors.transparent,
              ),
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  CircularProgressIndicator(value: downloadProgress.progress),
            ),
      child: Column(
        children: [
          Text(
            style: TextStyle(
              fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 14.sp,
            ),
            stream.name,
          ),
          Text(
            style: TextStyle(
              fontSize: Device.screenType == ScreenType.desktop ? 11.sp : 13.sp,
            ),
            stream.title,
          ),
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
          context.pushReplacement(
            '/player?media=$tmdbId&s=${episode?.seasonNumber}&e=${episode?.episodeNumber}',
            extra: stream,
          );
        } else {
          context.pushReplacement('/player?media=$tmdbId', extra: stream);
        }
      },
    );
  }
}
