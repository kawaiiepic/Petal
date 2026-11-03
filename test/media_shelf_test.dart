import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/arrow_button.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

Widget harness(Widget child, {double width = 360}) => ShadcnApp(
  home: Scaffold(
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Widget card(BuildContext context, int index) => MediaCard(
  label: 'Movie $index',
  image: const ColoredBox(color: Colors.pink),
);

void main() {
  testWidgets('portrait row shares spacing and renders no captions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(MediaShelf(itemCount: 8, itemBuilder: card)),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(HoverableItem);
    expect(tester.getSize(cards.first), const Size(135, 180));
    expect(
      tester.getTopLeft(cards.at(1)).dx - tester.getTopLeft(cards.first).dx,
      151,
    );
    expect(find.text('Movie 0'), findsNothing);
    expect(find.bySemanticsLabel('Movie 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('landscape row uses the same height and wide card proportions', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        MediaShelf(
          orientation: Orientation.landscape,
          itemCount: 8,
          itemBuilder: card,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(HoverableItem).first),
      const Size(320, 180),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical grid expands within an outer page scroll view', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        SingleChildScrollView(
          child: MediaShelf(
            scrollDirection: Axis.vertical,
            itemCount: 18,
            itemBuilder: card,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.shrinkWrap, isTrue);
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    expect(find.byType(ScrollableWidget), findsNothing);
    final size = tester.getSize(find.byType(HoverableItem).first);
    expect(size.width / size.height, closeTo(3 / 4, 0.001));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bounded vertical grid scrolls and survives switching orientation',
    (tester) async {
      Widget shelf(Orientation orientation) => harness(
        SizedBox(
          height: 240,
          child: MediaShelf(
            scrollDirection: Axis.vertical,
            orientation: orientation,
            itemCount: 50,
            itemBuilder: card,
          ),
        ),
      );
      await tester.pumpWidget(shelf(Orientation.portrait));
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.shrinkWrap, isFalse);
      await tester.drag(find.byType(GridView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(grid.controller!.offset, greaterThan(0));

      await tester.pumpWidget(shelf(Orientation.landscape));
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(HoverableItem).first);
      expect(size.width / size.height, closeTo(16 / 9, 0.001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hover arrows scroll within bounds and removal is safe', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(MediaShelf(itemCount: 8, itemBuilder: card)),
    );
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(ScrollableWidget)));
    await tester.pumpAndSettle();
    final arrows = find.byType(ArrowButton);
    final next = tester.widget<ArrowButton>(arrows.last);
    expect(next.visible, isTrue);
    await tester.tap(arrows.last);
    await tester.pumpAndSettle();
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    expect(controller.offset, greaterThan(0));
    for (var i = 0; i < 8; i++) {
      next.onPressed();
      await tester.pumpAndSettle();
    }
    expect(controller.offset, controller.position.maxScrollExtent);

    await mouse.removePointer();
    await tester.pumpWidget(harness(const SizedBox.shrink()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('card keeps tap actions and metadata on the image', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        MediaShelf(
          itemCount: 1,
          itemBuilder: (_, _) => MediaCard(
            label: 'Example movie',
            image: const ColoredBox(color: Colors.pink),
            onTap: () => taps++,
            overlay: const Positioned(
              bottom: 8,
              left: 8,
              child: Text('Tomorrow'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HoverableItem));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.text('Example movie'), findsNothing);
    expect(find.text('Tomorrow'), findsOneWidget);
    final bounds = tester.getRect(find.byType(HoverableItem));
    expect(bounds.contains(tester.getCenter(find.text('Tomorrow'))), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty shelf creates no scroll controller clients', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(MediaShelf(itemCount: 0, itemBuilder: card)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ScrollableWidget), findsNothing);
    expect(find.byType(MediaCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
