import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/home/watchlist_landscape_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class StartNowShelf extends StatefulWidget {
  const StartNowShelf({super.key});

  @override
  State<StartNowShelf> createState() => _StartNowShelfState();
}

class _StartNowShelfState extends State<StartNowShelf> {
  @override
  void initState() {
    super.initState();
    if (BackendApi.authState.selectedProfile != null) {
      BackendCache.fetchContinueWatching();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        return ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            final seen = {
              for (final item in list) '${item.mediaType.name}:${item.tmdbId}',
            };
            final items = UserLibrary.watchlistTitles()
                .where(
                  (title) =>
                      title.type == MediaType.show &&
                      !seen.contains('${title.type.name}:${title.tmdbId}'),
                )
                .take(12)
                .toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return HomeSection(
              title: 'Start now',
              child: MediaShelf(
                orientation: Orientation.landscape,
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    WatchlistLandscapeCard(item: items[index]),
              ),
            );
          },
        );
      },
    );
  }
}
