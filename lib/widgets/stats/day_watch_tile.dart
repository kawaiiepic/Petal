import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/day_watch.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DayWatchTile extends StatelessWidget {
  final DayWatch item;

  const DayWatchTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final name = snapshot.hasData
            ? (isShow
                  ? (snapshot.data as dynamic).name as String?
                  : (snapshot.data as dynamic).title as String?)
            : null;
        final detail = isShow && item.season != null && item.episode != null
            ? 'S${item.season}E${item.episode}'
            : 'Movie';
        return Button.ghost(
          alignment: Alignment.centerLeft,
          onPressed: () => context.push(
            isShow
                ? '/series?tmdb=${item.tmdbId}'
                : '/movie?tmdb=${item.tmdbId}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
