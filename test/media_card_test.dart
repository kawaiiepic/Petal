import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

import 'support/recording_adapter.dart';

Widget harness(Widget card) => ShadcnApp(
  home: Scaffold(child: SizedBox(width: 320, height: 180, child: card)),
);

List<MenuButton> menu(WidgetTester tester) => tester
    .widget<HoverableItem>(find.byType(HoverableItem))
    .contextItems!
    .whereType<MenuButton>()
    .toList();

void main() {
  final adapter = RecordingAdapter();
  setUpAll(() {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
  });
  setUp(() {
    TMDB.clearCache();
    adapter.requests.clear();
    adapter.respond = (_) => jsonBody({
      'id': 42,
      'images': {'logos': []},
    });
    UserLibrary.watchlist.value = {};
  });

  testWidgets(
    'shared defaults and shelf extras coexist; watchlist label stays current',
    (tester) async {
      var customActions = 0;
      await tester.pumpWidget(
        harness(
          MediaCard(
            image: const ColoredBox(color: Colors.pink),
            target: const MediaCardTarget(tmdbId: 42, type: MediaType.movie),
            extraContextItems: [
              MenuButton(
                child: const Text('Shelf action'),
                onPressed: (_) => customActions++,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      List<String?> labels() =>
          menu(tester).map((item) => (item.child as Text).data).toList();
      expect(
        labels(),
        containsAll([
          'Play',
          'Select Source',
          'More Info',
          'Add to Watchlist',
          'Mark as Watched',
          'Rate',
          'Shelf action',
        ]),
      );
      menu(tester).last.onPressed!(tester.element(find.byType(MediaCard)));
      expect(customActions, 1);
      UserLibrary.watchlist.value = {'movie:42'};
      await tester.pumpAndSettle();
      expect(labels(), contains('Remove from Watchlist'));
      expect(labels(), isNot(contains('Add to Watchlist')));
      expect(adapter.requests, isEmpty);
    },
  );

  testWidgets('shelf can explicitly opt out of default menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        MediaCard(
          image: const ColoredBox(color: Colors.pink),
          target: const MediaCardTarget(tmdbId: 42, type: MediaType.movie),
          showDefaultContextMenu: false,
          extraContextItems: [MenuButton(child: const Text('Only this shelf'))],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(menu(tester).length, 1);
    expect((menu(tester).single.child as Text).data, 'Only this shelf');
  });

  testWidgets('only landscape artwork loads logos; missing artwork is safe', (
    tester,
  ) async {
    Widget card(Orientation orientation) => harness(
      MediaCard(
        orientation: orientation,
        image: const ColoredBox(color: Colors.pink),
        target: const MediaCardTarget(tmdbId: 42, type: MediaType.show),
      ),
    );
    await tester.pumpWidget(card(Orientation.portrait));
    await tester.pumpAndSettle();
    expect(adapter.requests, isEmpty);
    await tester.pumpWidget(card(Orientation.landscape));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, 1);
    await tester.pumpWidget(card(Orientation.landscape));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, 1);
    expect(tester.takeException(), isNull);
  });
}
