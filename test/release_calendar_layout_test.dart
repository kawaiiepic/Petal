import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/upcoming_releases.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:petal/widgets/home/release_tile.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:petal/widgets/release_calendar.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('release calendar stacks on mobile and opens the selected day', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => UpcomingReleases.items.value = const []);
    final now = DateTime.now();
    final release = DateTime(now.year, now.month, now.day == 1 ? 2 : 1);

    await tester.pumpWidget(
      const ShadcnApp(
        home: Scaffold(child: SingleChildScrollView(child: ReleaseCalendar())),
      ),
    );
    UpcomingReleases.items.value = [
      UpcomingItem(
        type: MediaType.movie,
        tmdbId: 42,
        showName: 'Premiere',
        episodeName: '',
        season: 0,
        episode: 0,
        airDate: release,
      ),
    ];
    await tester.pump();
    final panels = find.byType(LibraryPanel);
    expect(
      tester.getTopLeft(panels.last).dy,
      greaterThan(tester.getBottomLeft(panels.first).dy),
    );
    expect(find.text('No releases scheduled for this day.'), findsOneWidget);
    await tester.tap(
      find.bySemanticsLabel(RegExp(r'^[A-Za-z]+ \d+, 1 release$')),
    );
    await tester.pump();
    expect(find.byType(ReleaseTile), findsOneWidget);
    expect(find.text('Movie premiere'), findsOneWidget);

    tester.view.physicalSize = const Size(1024, 740);
    await tester.pump();
    expect(
      tester.getTopLeft(panels.last).dy,
      tester.getTopLeft(panels.first).dy,
    );
    expect(
      tester.getTopLeft(panels.last).dx,
      greaterThan(tester.getTopRight(panels.first).dx),
    );
    await tester.tap(find.text('Today'));
    await tester.pump();
    expect(find.byType(ReleaseTile), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
