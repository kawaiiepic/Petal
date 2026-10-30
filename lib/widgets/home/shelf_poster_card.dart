import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ShelfPosterCard extends StatelessWidget {
  final ShelfItem item;

  const ShelfPosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final posterPath = snapshot.hasData
            ? (snapshot.data as dynamic).posterPath as String?
            : null;
        final name = snapshot.hasData
            ? (isShow
                  ? (snapshot.data as dynamic).name as String?
                  : (snapshot.data as dynamic).title as String?)
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HoverableItem(
                onTap: () => context.push(
                  isShow
                      ? '/series?tmdb=${item.tmdbId}'
                      : '/movie?tmdb=${item.tmdbId}',
                ),
                image: posterPath == null || posterPath.isEmpty
                    ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                    : CachedNetworkImage(
                        imageUrl: Api.proxyImage(
                          'https://image.tmdb.org/t/p/w342$posterPath',
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name ?? item.subtitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            if (item.subtitle != null)
              Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
          ],
        );
      },
    );
  }
}
