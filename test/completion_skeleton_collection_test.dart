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
import 'package:petal/pages/collection_home_page.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/collection/collection_card.dart';
import 'package:petal/widgets/media/media_artwork_placeholder.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

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
  setUpAll(() => BackendApi.dio = Dio()..httpClientAdapter = adapter);
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

  testWidgets(
    'finished badge resolves total from cached metadata and reacts to progress',
    (tester) async {
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
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
      BackendCache.watchHistory.value = [
        history(42, episodes: [1, .5]),
      ];
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
      expect(find.byIcon(LucideIcons.circlePlay), findsOneWidget);
      expect(adapter.requests.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

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
      expect(find.byType(CollectionCard), findsNothing);
      expect(find.byType(MediaArtworkPlaceholder), findsWidgets);
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
      final cards = tester
          .widgetList<CollectionCard>(find.byType(CollectionCard))
          .toList();
      expect(cards.length, 2);
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
      expect(find.byIcon(LucideIcons.imageOff), findsNWidgets(2));
      await tester.tap(find.text('Watched'));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<CollectionCard>(find.byType(CollectionCard)).length,
        3,
      );
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed collection metadata leaves visible cards instead of skeletons or holes',
    (tester) async {
      BackendCache.watchHistory.value = [
        history(7, episodes: [.5]),
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
