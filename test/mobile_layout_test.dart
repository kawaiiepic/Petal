import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/back_button.dart' as petal;
import 'package:petal/widgets/overview/overview_back_button.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('overview back control clears iPhone status bar and remains a 44px target', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ShadcnApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(393, 852),
          padding: EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: EdgeInsets.only(top: 59, bottom: 34),
        ),
        child: const Stack(fit: StackFit.expand, children: [
          ColoredBox(color: Colors.black),
          OverviewBackButton(),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(petal.BackButton));
    expect(rect.top, greaterThanOrEqualTo(67));
    expect(rect.width, 44);
    expect(rect.height, 44);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone shelves use compact gaps without stretching wide artwork', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ShadcnApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: MediaShelf(
          orientation: Orientation.landscape,
          itemCount: 4,
          itemBuilder: (_, index) => ColoredBox(
            key: ValueKey('item-$index'), color: Colors.pink),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final first = tester.getRect(find.byKey(const ValueKey('item-0')));
    final second = tester.getRect(find.byKey(const ValueKey('item-1')));
    expect(first.width / first.height, closeTo(16 / 9, .001));
    expect(first.width, lessThan(320));
    expect(second.left - first.right, closeTo(8, .001));
    expect(first.left, 0);
    expect(tester.takeException(), isNull);
  });
}
