import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/models/watch_history/next_episode.dart';
import 'package:petal/widgets/home/continue_watching_card.dart';
import 'package:petal/widgets/home/on_deck_shelf.dart';
import 'package:petal/widgets/home/watchlist_landscape_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

import 'support/recording_adapter.dart';

void main() {
  final adapter = RecordingAdapter();
  setUpAll(() {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
  });
  test(
    'partial progress updates the local last-watched date for movies and shows',
    () async {
      adapter.respond = null;
      BackendApi.authState.setLoggedIn({'id': 'user'});
      BackendApi.authState.setProfile(
        Profile(id: 'deck', userId: 'user', name: 'deck', createdAt: ''),
      );
      await BackendCache.fetchWatchHistory();
      BackendCache.continueWatching.value = [];
      final watchedAt = DateTime.utc(2026, 10, 30);
      await BackendApi.setProgress(
        42,
        MediaType.movie,
        .2,
        watchedAt: watchedAt,
        refresh: false,
      );
      await BackendApi.setProgress(
        43,
        MediaType.show,
        .3,
        season: 1,
        episode: 2,
        watchedAt: watchedAt,
        refresh: false,
      );
      expect(BackendCache.continueWatching.value.length, 2);
      expect(
        BackendCache.continueWatching.value.every(
          (item) => item.lastWatched == watchedAt,
        ),
        isTrue,
      );
      BackendApi.authState.setLoggedIn(null);
    },
  );

  testWidgets(
    'On Deck reacts to watchlist changes alongside active playback cards',
    (tester) async {
      adapter.respond = (_) => jsonBody({
        'id': 42,
        'name': 'Example',
        'images': {'logos': []},
      });
      BackendApi.authState.setLoggedIn(null);
      TMDB.clearCache();
      BackendCache.watchHistory.value = [];
      BackendCache.continueWatching.value = [
        ShowItem(
          tmdbId: 42,
          nextEpisode: NextEpisode(season: 1, episode: 2, completion: 0),
          seasons: [],
        ),
      ];
      UserLibrary.watchlist.value = {'movie:43'};
      await tester.pumpWidget(
        Sizer(
          builder: (_, _, _) =>
              const ShadcnApp(home: Scaffold(child: OnDeckShelf())),
        ),
      );
      // Missing artwork deliberately keeps its skeleton animation active.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ContinueWatchingCard), findsOneWidget);
      expect(find.byType(WatchlistLandscapeCard), findsOneWidget);
      expect(
        tester
            .widget<WatchlistLandscapeCard>(find.byType(WatchlistLandscapeCard))
            .item
            .tmdbId,
        43,
      );
      UserLibrary.watchlist.value = {'movie:44'};
      // Missing artwork deliberately keeps its skeleton animation active.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<WatchlistLandscapeCard>(find.byType(WatchlistLandscapeCard))
            .item
            .tmdbId,
        44,
      );
      UserLibrary.watchlist.value = {};
      // Missing artwork deliberately keeps its skeleton animation active.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(WatchlistLandscapeCard), findsNothing);
      expect(find.byType(ContinueWatchingCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      BackendCache.continueWatching.value = [];
    },
  );
}
