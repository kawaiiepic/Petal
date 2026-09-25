import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class ShelfItem {
  final int tmdbId;
  final MediaType type;
  final String? subtitle;

  const ShelfItem({required this.tmdbId, required this.type, this.subtitle});
}

class PosterShelf extends StatelessWidget {
  final String title;
  final List<ShelfItem> items;

  const PosterShelf({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: title,
      child: SizedBox(
        height: 23.h,
        child: ScrollableWidget(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => SizedBox(width: 28.w, child: _PosterCard(item: items[index])),
          ),
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final ShelfItem item;

  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final posterPath = snapshot.hasData ? (snapshot.data as dynamic).posterPath as String? : null;
        final name = snapshot.hasData
            ? (isShow ? (snapshot.data as dynamic).name as String? : (snapshot.data as dynamic).title as String?)
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HoverableItem(
                onTap: () => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
                image: posterPath == null || posterPath.isEmpty
                    ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                    : CachedNetworkImage(imageUrl: Api.proxyImage('https://image.tmdb.org/t/p/w342$posterPath'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            Text(name ?? item.subtitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            if (item.subtitle != null)
              Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55))),
          ],
        );
      },
    );
  }
}
