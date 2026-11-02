import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/next_episode.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/home/on_deck_shelf.dart';
import 'package:petal/widgets/home/continue_watching_card.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_progress_bar.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

import 'support/recording_adapter.dart';

ShowItem episode() => ShowItem(
  tmdbId: 42,
  nextEpisode: NextEpisode(season: 2, episode: 3, completion: .4),
  seasons: [],
);
void main() {
  final adapter = RecordingAdapter();
  setUpAll(() {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
  });
  setUp(() {
    BackendApi.authState.setLoggedIn(null);
    BackendCache.continueWatching.value = [];
    BackendCache.watchHistory.value = [];
    UserLibrary.watchlist.value = {};
    TMDB.clearCache();
    adapter.requests.clear();
    adapter.respond = (_) => jsonBody({
      'id': 42,
      'name': 'Episode',
      'title': 'Movie',
      'season_number': 2,
      'episode_number': 3,
      'images': {'logos': [], 'backdrops': []},
    });
  });

  testWidgets(
    'progress bars show exact partial playback and hide at the watched threshold',
    (tester) async {
      Widget bar(double progress) => ShadcnApp(
        home: Scaffold(
          child: SizedBox(
            width: 200,
            child: MediaProgressBar(progress: progress),
          ),
        ),
      );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(bar(.4));
      expect(find.bySemanticsLabel('Playback progress'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        .4,
      );
      for (final value in [0.0, .9, 1.0]) {
        await tester.pumpWidget(bar(value));
        expect(find.byType(FractionallySizedBox), findsNothing);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'shared cards react to the displayed episode without using a show aggregate',
    (tester) async {
      BackendCache.continueWatching.value = [episode()];
      Widget card(MediaCardTarget target) => ShadcnApp(
        home: Scaffold(
          child: SizedBox(
            width: 320,
            height: 180,
            child: MediaCard(
              showLogo: false,
              image: const ColoredBox(color: Colors.black),
              target: target,
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        card(
          const MediaCardTarget(
            tmdbId: 42,
            type: MediaType.show,
            season: 2,
            episode: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        .4,
      );
      BackendCache.continueWatching.value = [
        ShowItem(
          tmdbId: 42,
          nextEpisode: NextEpisode(season: 2, episode: 3, completion: .6),
          seasons: [],
        ),
      ];
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        .6,
      );
      await tester.pumpWidget(
        card(const MediaCardTarget(tmdbId: 42, type: MediaType.show)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(adapter.requests, isEmpty);
    },
  );

  test(
    'episode lookup uses matching history when next-up points elsewhere',
    () {
      final history = WatchHistoryItem.fromJson({
        'tmdb_id': 42,
        'media_type': 'show',
        'episodes': [
          {'season': 2, 'episode': 1, 'completion': .25},
        ],
      });
      expect(
        WatchProgress.playbackCompletion(
          tmdbId: 42,
          type: MediaType.show,
          season: 2,
          episode: 1,
          history: [history],
          nextUp: [episode()],
        ),
        .25,
      );
      expect(
        WatchProgress.playbackCompletion(
          tmdbId: 42,
          type: MediaType.show,
          history: [history],
          nextUp: [episode()],
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'On Deck opens exact episode and movie overviews and retains Resume action',
    (tester) async {
      BackendCache.continueWatching.value = [
        episode(),
        MovieItem(tmdbId: 43, completion: .5),
      ];
      Uri? destination;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(child: OnDeckShelf()),
          ),
          for (final path in ['/episode', '/movie', '/player'])
            GoRoute(
              path: path,
              builder: (_, state) {
                destination = state.uri;
                return const Scaffold(child: Text('Details'));
              },
            ),
        ],
      );
      await tester.pumpWidget(
        Sizer(builder: (_, _, _) => ShadcnApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();
      Finder target(int id) => find.byWidgetPredicate(
        (widget) => widget is MediaCard && widget.target?.tmdbId == id,
      );
      await tester.tap(target(42));
      await tester.pumpAndSettle();
      expect(destination!.path, '/episode');
      expect(destination!.queryParameters, {'tmdb': '42', 's': '2', 'e': '3'});
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(target(43));
      await tester.pumpAndSettle();
      expect(destination!.toString(), '/movie?tmdb=43');
      router.go('/');
      await tester.pumpAndSettle();
      final hover = tester.widget<HoverableItem>(
        find.descendant(of: target(42), matching: find.byType(HoverableItem)),
      );
      final resume = hover.contextItems!.whereType<MenuButton>().firstWhere(
        (button) =>
            button.child is Text && (button.child as Text).data == 'Resume',
      );
      resume.onPressed!(tester.element(target(42)));
      await tester.pumpAndSettle();
      expect(destination!.path, '/player');
      expect(destination!.queryParameters['p'], '0.4');
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );

  testWidgets('Continue Watching keeps direct resume playback', (tester) async {
    Uri? destination;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            child: SizedBox(
              width: 320,
              height: 180,
              child: ContinueWatchingCard(state: episode()),
            ),
          ),
        ),
        GoRoute(
          path: '/player',
          builder: (_, state) {
            destination = state.uri;
            return const Scaffold(child: Text('Playing'));
          },
        ),
      ],
    );
    await tester.pumpWidget(ShadcnApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MediaCard));
    await tester.pumpAndSettle();
    expect(destination!.queryParameters, {
      'media': '42',
      's': '2',
      'e': '3',
      'p': '0.4',
    });
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}
