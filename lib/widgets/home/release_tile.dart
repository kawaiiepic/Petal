import 'package:go_router/go_router.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ReleaseTile extends StatelessWidget {
  const ReleaseTile({super.key, required this.item});

  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final movie = item.type == MediaType.movie;
    final colors = Theme.of(context).colorScheme;
    return Button.secondary(
      onPressed: () => context.push(
        movie ? '/movie?tmdb=${item.tmdbId}' : '/series?tmdb=${item.tmdbId}',
      ),
      child: Row(
        spacing: 10,
        children: [
          if (item.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 52,
                height: 34,
                child: MediaArtwork(imageUrl: item.image),
              ),
            )
          else
            Icon(movie ? LucideIcons.film : LucideIcons.tv, size: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.showName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  movie
                      ? 'Movie premiere'
                      : 'S${item.season} · E${item.episode} · ${item.episodeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16),
        ],
      ),
    );
  }
}
