import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/social/activity_item.dart';
import 'package:petal/utils/watch_meta.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FriendActivityCard extends StatefulWidget {
  const FriendActivityCard({super.key, required this.item});

  final ActivityItem item;

  @override
  State<FriendActivityCard> createState() => _FriendActivityCardState();
}

class _FriendActivityCardState extends State<FriendActivityCard> {
  late var _artwork = _loadArtwork();

  bool get _isShow => widget.item.mediaType != 'movie';

  @override
  void didUpdateWidget(covariant FriendActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.tmdbId != widget.item.tmdbId ||
        oldWidget.item.mediaType != widget.item.mediaType) {
      _artwork = _loadArtwork();
    }
  }

  Future<({String? title, String? backdrop, String? poster})>
  _loadArtwork() async {
    if (_isShow) {
      final show = await TMDB.tvShow(widget.item.tmdbId);
      return (
        title: show.name,
        backdrop: show.backdropPath,
        poster: show.posterPath,
      );
    }
    final movie = await TMDB.movie(widget.item.tmdbId);
    return (
      title: movie.title,
      backdrop: movie.backdropPath,
      poster: movie.posterPath,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _artwork,
    builder: (context, snapshot) {
      final item = widget.item;
      final data = snapshot.data;
      final path = data?.backdrop?.isNotEmpty == true
          ? data!.backdrop
          : data?.poster;
      final title = data?.title?.isNotEmpty == true
          ? data!.title!
          : (_isShow ? 'TV show' : 'Movie');
      final avatar = item.avatar;
      final timestamp = WatchMeta.relative(item.at);
      return MediaCard(
        orientation: Orientation.landscape,
        showLogo: false,
        showDefaultContextMenu: false,
        imageUrl: path == null || path.isEmpty
            ? null
            : Api.proxyImage(
                path.startsWith('http')
                    ? path
                    : 'https://image.tmdb.org/t/p/w780$path',
              ),
        semanticLabel: '${item.name} watched $title · $timestamp',
        onTap: () => context.push(
          '/${_isShow ? 'series' : 'movie'}?tmdb=${item.tmdbId}',
        ),
        overlay: Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x0008070C), Color(0xF508070C)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
              child: Row(
                spacing: 8,
                children: [
                  Avatar(
                    size: 30,
                    initials: item.name.isEmpty
                        ? '?'
                        : item.name.characters.first,
                    provider: avatar == null || avatar.isEmpty
                        ? null
                        : CachedNetworkImageProvider(
                            '${Api.ProfileUrl}/$avatar',
                          ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.name} · $timestamp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFDFDFE4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
