import 'package:petal/models/tmdb/tmdb_video.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/overview/overview_thumbnail_caption.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:url_launcher/url_launcher.dart';

class TrailersShelf extends StatelessWidget {
  final List<TmdbVideo> videos;
  const TrailersShelf({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final trailers = videos.where((v) => v.site == 'YouTube' &&
      (v.type == 'Trailer' || v.type == 'Teaser') &&
      v.key.isNotEmpty && seen.add(v.key)).toList();
    if (trailers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trailers').h4,
        const SizedBox(height: 12),
        MediaShelf(
          orientation: Orientation.landscape,
          cardWidth: 208, cardHeight: 117, spacing: 10,
          padding: EdgeInsets.zero,
          itemCount: trailers.length,
          itemBuilder: (context, index) {
            final trailer = trailers[index];
            return MediaCard(
              orientation: Orientation.landscape,
              imageUrl: trailer.youtubeThumbnail,
              label: trailer.name,
              showLogo: false,
              showDefaultContextMenu: false,
              onTap: () => launchUrl(Uri.parse(trailer.youtubeUrl)),
              overlay: Positioned.fill(
                child: Stack(
                  children: [
                    const Align(alignment: Alignment.topRight,
                      child: Padding(padding: EdgeInsets.all(10),
                        child: Icon(LucideIcons.play, color: Colors.white, size: 22))),
                    OverviewThumbnailCaption(title: trailer.name, subtitle: trailer.type),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
