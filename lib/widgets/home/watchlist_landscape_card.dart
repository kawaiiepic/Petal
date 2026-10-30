import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class WatchlistLandscapeCard extends StatelessWidget {
  final LibraryTitle item;

  const WatchlistLandscapeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        String? image;
        String name = '';
        if (snapshot.hasData) {
          if (isShow) {
            final show = snapshot.data as dynamic;
            final backdrop = show.backdropPath as String?;
            final poster = show.posterPath as String?;
            name = (show.name as String?) ?? '';
            final path = (backdrop != null && backdrop.isNotEmpty)
                ? backdrop
                : poster;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else {
            final movie = snapshot.data as dynamic;
            final backdrop = movie.backdropPath as String?;
            final poster = movie.posterPath as String?;
            name = (movie.title as String?) ?? '';
            final path = (backdrop != null && backdrop.isNotEmpty)
                ? backdrop
                : poster;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          }
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(2.w, 8, 2.w, 8),
          child: Column(
            spacing: 8,
            children: [
              Expanded(
                child: HoverableItem(
                  orientation: Orientation.landscape,
                  onTap: () => context.push(
                    isShow
                        ? '/series?tmdb=${item.tmdbId}'
                        : '/movie?tmdb=${item.tmdbId}',
                  ),
                  contextItems: [
                    MenuButton(
                      leading: const Icon(LucideIcons.play),
                      onPressed: (_) => context.push(
                        isShow
                            ? '/series?tmdb=${item.tmdbId}'
                            : '/movie?tmdb=${item.tmdbId}',
                      ),
                      child: const Text('Play'),
                    ),
                    MenuButton(
                      leading: const Icon(LucideIcons.info),
                      onPressed: (_) => context.push(
                        isShow
                            ? '/series?tmdb=${item.tmdbId}'
                            : '/movie?tmdb=${item.tmdbId}',
                      ),
                      child: const Text('More Info'),
                    ),
                  ],
                  image: image == null
                      ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                      : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
                ),
              ),
              SizedBox(
                height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
                child: Column(
                  children: [
                    Text(
                      name.isEmpty ? 'Loading...' : name,
                      style: TextStyle(fontSize: 15.px),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Start now',
                      style: TextStyle(fontSize: 15.px),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
