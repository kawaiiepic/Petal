import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/widgets/home/featured_autoplay.dart';

void main() {
  testWidgets(
    'autoplay continues on hover but pauses for a press, backgrounding and reduced motion',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var advances = 0;
      late Animation<double> timing;
      const banner = Key('banner');

      Widget host({required bool reduceMotion}) => MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reduceMotion,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: FeaturedAutoplay(
              enabled: true,
              onAdvance: () => advances++,
              child: Builder(
                builder: (context) {
                  timing = FeaturedAutoplay.progressOf(context);
                  return const SizedBox(key: banner, width: 200, height: 160);
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(host(reduceMotion: true));
      await tester.pump(FeaturedAutoplay.interval);
      expect(advances, 0);
      expect(timing.value, 0);
      await tester.pumpWidget(host(reduceMotion: false));
      await tester.pump();
      const midpoint = Duration(seconds: 3);
      await tester.pump(midpoint);
      expect(timing.value, closeTo(3 / 7, .01));
      await tester.pump(FeaturedAutoplay.interval - midpoint);
      expect(advances, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      final center = tester.getCenter(find.byKey(banner));
      await mouse.addPointer(location: center);
      await tester.pump();
      await tester.pump(FeaturedAutoplay.interval);
      expect(advances, 2);
      await mouse.down(center);
      await tester.pump(FeaturedAutoplay.interval);
      expect(advances, 2);
      await mouse.up();
      await mouse.removePointer();
      await tester.pump();
      await tester.pump(FeaturedAutoplay.interval);
      expect(advances, 3);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(FeaturedAutoplay.interval);
      expect(advances, 3);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(FeaturedAutoplay.interval);
      expect(advances, 4);
    },
  );
}
