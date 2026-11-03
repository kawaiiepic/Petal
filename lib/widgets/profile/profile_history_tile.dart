import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ProfileHistoryTile extends StatelessWidget {
  final WatchHistoryItem item;

  const ProfileHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.mediaType == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final name = snapshot.hasData
            ? (isShow
                  ? (snapshot.data as dynamic).name as String?
                  : (snapshot.data as dynamic).title as String?)
            : null;
        return Button.ghost(
          alignment: Alignment.centerLeft,
          onPressed: () => context.push(
            isShow
                ? '/series?tmdb=${item.tmdbId}'
                : '/movie?tmdb=${item.tmdbId}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              name ?? (isShow ? 'Show ${item.tmdbId}' : 'Movie ${item.tmdbId}'),
            ),
          ),
        );
      },
    );
  }
}
