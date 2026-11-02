import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/utils/on_deck_selection.dart';
import 'package:petal/widgets/home/continue_watching_card.dart';
import 'package:petal/widgets/home/watchlist_landscape_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OnDeckShelf extends StatefulWidget {
  const OnDeckShelf({super.key});

  @override
  State<OnDeckShelf> createState() => _OnDeckShelfState();
}

class _OnDeckShelfState extends State<OnDeckShelf> {
  @override
  void initState() {
    super.initState();
    _onAuth();
    BackendApi.authState.addListener(_onAuth);
  }

  void _onAuth() {
    if (BackendApi.authState.selectedProfile != null) {
      BackendCache.fetchContinueWatching();
      BackendCache.fetchWatchHistory();
      UserLibrary.load();
    }
  }

  @override
  void dispose() {
    BackendApi.authState.removeListener(_onAuth);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      BackendCache.continueWatching,
      BackendCache.watchHistory,
      UserLibrary.watchlist,
    ]),
    builder: (context, _) {
      final entries = selectOnDeck(
        progress: BackendCache.continueWatching.value,
        history: BackendCache.watchHistory.value,
        watchlist: UserLibrary.watchlistTitles(),
      );
      if (entries.isEmpty) return const SizedBox.shrink();
      return HomeSection(
        title: 'On deck',
        child: MediaShelf(
          orientation: Orientation.landscape,
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return entry.progress != null
                ? ContinueWatchingCard(
                    key: ValueKey('deck-${entry.key}'),
                    state: entry.progress!,
                  )
                : WatchlistLandscapeCard(
                    key: ValueKey('deck-${entry.key}'),
                    item: entry.watchlistTitle!,
                  );
          },
        ),
      );
    },
  );
}
