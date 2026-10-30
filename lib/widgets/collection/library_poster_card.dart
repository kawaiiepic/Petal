import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LibraryPosterCard extends StatelessWidget {
  final LibraryTitle title;

  const LibraryPosterCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isShow = title.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(title.tmdbId) : TMDB.movie(title.tmdbId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Avatar(initials: '', borderRadius: 12).asSkeleton();
        }

        final posterPath = (snapshot.data as dynamic).posterPath as String?;
        final name = isShow
            ? (snapshot.data as dynamic).name as String?
            : (snapshot.data as dynamic).title as String?;
        if (posterPath == null || posterPath.isEmpty) {
          return const SizedBox.shrink();
        }

        final badge = title.rating == TitleRating.love
            ? 'Loved'
            : title.rating == TitleRating.like
            ? 'Liked'
            : 'Watchlist';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HoverableItem(
                image: CachedNetworkImage(
                  imageUrl: Api.proxyImage(
                    'https://image.tmdb.org/t/p/w342$posterPath',
                  ),
                  fit: BoxFit.cover,
                ),
                onTap: () => context.push(
                  isShow
                      ? '/series?tmdb=${title.tmdbId}'
                      : '/movie?tmdb=${title.tmdbId}',
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name ?? badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}
