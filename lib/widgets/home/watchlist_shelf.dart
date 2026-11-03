import 'package:petal/api/user_library.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/poster_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchlistShelf extends StatelessWidget {
  const WatchlistShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserLibrary.watchlist,
      builder: (context, _, __) {
        final items = UserLibrary.watchlistTitles()
            .take(12)
            .map((t) => ShelfItem(tmdbId: t.tmdbId, type: t.type))
            .toList();
        return PosterShelf(title: 'From your watchlist', items: items);
      },
    );
  }
}
