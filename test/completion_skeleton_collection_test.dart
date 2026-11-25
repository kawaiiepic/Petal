import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/pages/collection_home_page.dart';
import 'package:petal/pages/watch_history_page.dart';
import 'package:petal/utils/group_watch_history.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/collection/collection_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/library/history_title_card.dart';
import 'package:petal/widgets/library/history_title_dialog.dart';
import 'package:petal/widgets/media/media_artwork_placeholder.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

import 'support/recording_adapter.dart';

WatchHistoryItem history(
  int id, {
  String type = 'show',
  List<double> episodes = const [],
  double completion = 0,
}) => WatchHistoryItem.fromJson({
  'tmdb_id': id,
  'media_type': type,
  'updated_at': 1700000000,
  'completion': completion,
  'episodes': [
    for (var i = 0; i < episodes.length; i++)
      {'season': 1, 'episode': i + 1, 'completion': episodes[i]},
  ],
});
Widget harness(Widget child) => ShadcnApp(home: Scaffold(child: child));
void main() {
  final adapter = RecordingAdapter();
  setUpAll(() {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
    SharedPreferences.setMockInitialValues({});
  });
  setUp(() {
    TMDB.clearCache();
    BackendCache.watchHistory.value = [];
    BackendCache.continueWatching.value = [];
    UserLibrary.watchlist.value = {};
    UserLibrary.ratings.value = {};
    adapter.requests.clear();
    adapter.respond = (_) => jsonBody({
      'id': 42,
      'name': 'Title',
      'title': 'Title',
      'number_of_episodes': 2,
      'images': {'logos': []},
    });
  });

  test(
    'finished show needs a known total and 90% completion for every episode',
    () {
      bool finished(List<double> episodes, int? total) =>
          WatchProgress.titleFinished(
            tmdbId: 42,
            type: MediaType.show,
            totalEpisodes: total,
            history: [history(42, episodes: episodes)],
          );
      expect(finished([1, .9], 2), isTrue);
      expect(finished([1, .89], 2), isFalse);
      expect(finished([1], 2), isFalse);
      expect(finished([1, 1], null), isFalse);
      expect(finished([1, 1], 0), isFalse);
    },
  );

  testWidgets('watched actions use cached episode totals without a badge', (
    tester,
  ) async {
    BackendCache.watchHistory.value = [
      history(42, episodes: [1, 1]),
    ];
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 135,
          height: 180,
          child: MediaCard(
            image: ColoredBox(color: Colors.pink),
            target: MediaCardTarget(tmdbId: 42, type: MediaType.show),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Iterable<String?> actions() => tester
        .widget<HoverableItem>(find.byType(HoverableItem))
        .contextItems!
        .whereType<MenuButton>()
        .map((button) => (button.child as Text).data);
    expect(actions(), contains('Mark as Unwatched'));
    expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
    BackendCache.watchHistory.value = [
      history(42, episodes: [1, .5]),
    ];
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
    expect(actions(), contains('Mark as Watched'));
    expect(find.byIcon(LucideIcons.circlePlay), findsNothing);
    expect(adapter.requests.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'loading is inert, then missing artwork becomes a static fallback',
    (tester) async {
      var taps = 0;
      Widget card(bool loading) => harness(
        SizedBox(
          width: 135,
          height: 180,
          child: MediaCard(
            isLoading: loading,
            onTap: () => taps++,
            target: const MediaCardTarget(tmdbId: 42, type: MediaType.show),
          ),
        ),
      );
      await tester.pumpWidget(card(true));
      expect(
        tester
            .widget<MediaArtworkPlaceholder>(
              find.byType(MediaArtworkPlaceholder),
            )
            .loading,
        isTrue,
      );
      expect(
        tester.widget<HoverableItem>(find.byType(HoverableItem)).contextItems,
        isEmpty,
      );
      await tester.tap(find.byType(HoverableItem));
      expect(taps, 0);
      await tester.pumpWidget(card(false));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MediaArtworkPlaceholder>(
              find.byType(MediaArtworkPlaceholder),
            )
            .loading,
        isFalse,
      );
      expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  List<WatchHistoryItem> splitHistory() => [
    WatchHistoryItem.fromJson({
      'tmdb_id': 42,
      'media_type': 'show',
      'updated_at': 1700086400,
      'episodes': [
        {'season': 1, 'episode': 1, 'completion': .5},
      ],
    }),
    history(42, type: 'movie', completion: .25),
    WatchHistoryItem.fromJson({
      'tmdb_id': 42,
      'media_type': 'show',
      'updated_at': 1700000000,
      'episodes': [
        {'season': 1, 'episode': 1, 'completion': .25},
        {'season': 2, 'episode': 2, 'completion': 1},
      ],
    }),
  ];

  test('history groups title snapshots without merging movie and show IDs', () {
    final grouped = groupWatchHistory(splitHistory());
    expect(grouped.map((item) => item.mediaType), [
      MediaType.show,
      MediaType.movie,
    ]);
    expect(grouped.first.episodes.length, 2);
    expect(
      grouped.first.episodes
          .firstWhere((episode) => episode.season == 1)
          .completion,
      .5,
    );
  });

  testWidgets(
    'history opens one show card with season-grouped episode controls',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(
          const TvLayout(
            screenType: ScreenType.mobile,
            child: WatchHistoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      BackendCache.watchHistory.value = splitHistory();
      await tester.pumpAndSettle();

      final showCard = find.byKey(const ValueKey((MediaType.show, 42)));
      expect(showCard, findsOneWidget);
      expect(find.byType(HistoryTitleCard), findsNWidgets(2));
      expect(find.text('Reset progress'), findsNothing);
      await tester.tap(showCard);
      await tester.pumpAndSettle();
      final dialog = find.byType(HistoryTitleDialog);
      expect(dialog, findsOneWidget);
      expect(find.text('Season 1'), findsOneWidget);
      expect(find.text('Episode 1'), findsOneWidget);
      expect(find.text('50% · 0 plays'), findsOneWidget);
      expect(find.text('Reset progress').hitTestable(), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Episode 2').hitTestable(),
        120,
        scrollable: find.descendant(
          of: dialog,
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Season 2'), findsOneWidget);
      expect(find.text('Episode 2').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'collection partitions finished shows before layout and keeps missing posters visible',
    (tester) async {
      BackendCache.watchHistory.value = [
        history(42, episodes: [1, 1]),
        history(42, type: 'movie', completion: .5),
        history(7, episodes: [.5]),
      ];
      final pending = Completer<ResponseBody>();
      adapter.respond = (_) => pending.future;
      await tester.pumpWidget(harness(const CollectionHomePage()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Watching'), findsOneWidget);
      pending.complete(
        jsonBody({
          'id': 42,
          'name': 'Title',
          'title': 'Title',
          'number_of_episodes': 2,
          'images': {'logos': []},
        }),
      );
      await tester.pumpAndSettle();
      final watching = find.ancestor(
        of: find.text('Watching'),
        matching: find.byType(HomeSection),
      );
      final cards = tester
          .widgetList<CollectionCard>(
            find.descendant(
              of: watching,
              matching: find.byType(CollectionCard),
            ),
          )
          .toList();
      expect(cards.length, 2);
      final overlays = tester.widgetList<WatchMetaOverlay>(
        find.descendant(of: watching, matching: find.byType(WatchMetaOverlay)),
      );
      expect(overlays, hasLength(2));
      expect(overlays.every((overlay) => overlay.playback), isTrue);
      expect(
        cards.any(
          (card) =>
              card.item.tmdbId == 42 && card.item.mediaType == MediaType.movie,
        ),
        isTrue,
      );
      expect(cards.any((card) => card.item.tmdbId == 7), isTrue);
      expect(
        cards.any(
          (card) =>
              card.item.tmdbId == 42 && card.item.mediaType == MediaType.show,
        ),
        isFalse,
      );
      expect(
        find.descendant(
          of: watching,
          matching: find.byIcon(LucideIcons.imageOff),
        ),
        findsNWidgets(2),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('collection-show-42')).hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final watched = find.ancestor(
        of: find.text('Watched'),
        matching: find.byType(HomeSection),
      );
      expect(
        find.descendant(
          of: watched,
          matching: find.byKey(const ValueKey('collection-show-42')),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed collection metadata leaves visible cards instead of skeletons or holes',
    (tester) async {
      BackendCache.watchHistory.value = [
        history(77, episodes: [.5]),
      ];
      adapter.respond = (_) => throw StateError('Offline');
      await tester.pumpWidget(harness(const CollectionHomePage()));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionCard), findsOneWidget);
      expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
