import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class FriendActivity extends StatefulWidget {
  const FriendActivity({super.key});

  @override
  State<FriendActivity> createState() => _FriendActivityState();
}

class _FriendActivityState extends State<FriendActivity> {
  late Future<List<ActivityItem>> _future = SocialApi.activity();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ActivityItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Friend activity',
          child: SizedBox(
            height: 22.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.take(12).length,
              itemBuilder: (context, index) => _ActivityCard(item: items[index]),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.mediaType != 'movie';
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        String? image;
        if (snapshot.hasData) {
          final data = snapshot.data as dynamic;
          final backdrop = data.backdropPath as String?;
          final poster = data.posterPath as String?;
          final path = (backdrop != null && backdrop.isNotEmpty) ? backdrop : poster;
          if (path != null && path.isNotEmpty) {
            image = path.startsWith('http') ? Api.proxyImage(path) : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
          }
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(2.w, 8, 2.w, 8),
          child: SizedBox(
            width: 55.w,
            child: HoverableItem(
              orientation: Orientation.landscape,
              onTap: () => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
              image: image == null
                  ? Avatar(initials: item.name.isNotEmpty ? item.name[0] : '?', borderRadius: 12)
                  : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
              extraWidget: Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xE6101018), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${item.name} \u00b7 ${WatchMeta.relative(item.at)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
