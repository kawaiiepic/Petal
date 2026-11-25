import 'package:petal/models/tmdb/tmdb_video.dart';
import 'package:petal/widgets/media/media_card.dart';
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
          orientation: Orientation.portrait,
          cardWidth: 116, cardHeight: 230, spacing: 10,
          padding: EdgeInsets.zero,
          itemCount: trailers.length,
          itemBuilder: (context, index) {
            final trailer = trailers[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(aspectRatio: 2 / 3, child: MediaCard(
                  orientation: Orientation.portrait,
                  imageUrl: trailer.youtubeThumbnail,
                  label: trailer.name,
                  showLogo: false,
                  showDefaultContextMenu: false,
                  onTap: () => launchUrl(Uri.parse(trailer.youtubeUrl)),
                  overlay: const Center(child: Icon(LucideIcons.play,
                    color: Colors.white, size: 30)),
                )),
                const SizedBox(height: 5),
                Text(trailer.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(trailer.type, maxLines: 1, style: TextStyle(fontSize: 11,
                  color: Theme.of(context).colorScheme.mutedForeground)),
              ],
            );
          },
        ),
      ],
    );
  }
}
