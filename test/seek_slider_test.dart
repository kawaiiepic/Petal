import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/seek_slider.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FakeSeekPlayer extends PlatformPlayer {
  final targets = <Duration>[];
  Completer<void>? pending;
  bool fail = false;
  FakeSeekPlayer({Duration duration = const Duration(seconds: 100)})
    : super(configuration: const PlayerConfiguration()) {
    state = PlayerState(
      position: const Duration(seconds: 10),
      duration: duration,
    );
  }
  @override
  Future<void> seek(Duration target) async {
    targets.add(target);
    await pending?.future;
    if (fail) throw StateError('Seek rejected');
    position(target);
  }

  void position(Duration position) {
    state = state.copyWith(position: position);
    positionController.add(position);
  }

  void buffering(bool buffering) {
    state = state.copyWith(buffering: buffering);
    bufferingController.add(buffering);
  }

  void playing(bool playing) {
    state = state.copyWith(playing: playing);
    playingController.add(playing);
  }

  void duration(Duration duration) {
    state = state.copyWith(duration: duration);
    durationController.add(duration);
  }
}

Widget harness(Player player, {bool visible = true}) => ShadcnApp(
  home: Scaffold(
    child: SizedBox(
      width: 400,
      child: SeekSlider(player: player, visible: visible),
    ),
  ),
);

void main() {
  testWidgets(
    'releasing after a rendered drag sends the final position exactly once',
    (tester) async {
      final native = FakeSeekPlayer();
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(harness(player));
      final rect = tester.getRect(find.byType(Slider));
      final gesture = await tester.startGesture(
        Offset(rect.left + rect.width * .1, rect.center.dy),
      );
      await gesture.moveBy(Offset(rect.width * .3, 0));
      await tester.pump();
      await gesture.moveBy(Offset(rect.width * .2, 0));
      await tester.pump();
      final dragged = tester.widget<Slider>(find.byType(Slider)).value.value;
      expect(dragged, greaterThan(.1));
      expect(native.targets, isEmpty);
      await gesture.up();
      await tester.pump();
      expect(native.targets.length, 1);
      expect(
        native.targets.single.inMicroseconds,
        (dragged * native.state.duration.inMicroseconds).round(),
      );
      expect(
        tester.widget<Slider>(find.byType(Slider)).value.value,
        closeTo(dragged, .001),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'rapid seeks keep the newest target and ignore older command completion',
    (tester) async {
      final native = FakeSeekPlayer()..pending = Completer<void>();
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(harness(player));
      void seek(double value) {
        final slider = tester.widget<Slider>(find.byType(Slider));
        slider.onChangeStart!(SliderValue.single(value));
        slider.onChanged!(SliderValue.single(value));
        slider.onChangeEnd!(SliderValue.single(value));
      }

      seek(.3);
      await tester.pump();
      final first = native.pending!;
      native.pending = Completer<void>();
      seek(.7);
      await tester.pump();
      first.complete();
      await tester.pump();
      expect(
        tester.widget<Slider>(find.byType(Slider)).value.value,
        closeTo(.7, .001),
      );
      native.pending!.complete();
      await tester.pumpAndSettle();
      expect(native.targets, [
        const Duration(seconds: 30),
        const Duration(seconds: 70),
      ]);
      expect(
        tester.widget<Slider>(find.byType(Slider)).value.value,
        closeTo(.7, .001),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'native position is not throttled and timeline freezes while buffering',
    (tester) async {
      final native = FakeSeekPlayer();
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(harness(player));
      native.position(const Duration(seconds: 20));
      await tester.pump();
      native.position(const Duration(seconds: 60));
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value.value, .6);
      native.playing(true);
      native.buffering(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(tester.widget<Slider>(find.byType(Slider)).value.value, .6);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'unknown duration is disabled and duration updates enable seeking safely',
    (tester) async {
      final native = FakeSeekPlayer(duration: Duration.zero);
      native.state = native.state.copyWith(buffer: const Duration(seconds: 10));
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(harness(player));
      var slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.enabled, isFalse);
      expect(slider.hintValue!.value, 0);
      native.duration(const Duration(seconds: 100));
      await tester.pump();
      slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.enabled, isTrue);
      expect(slider.hintValue!.value, .1);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'seek failures restore actual position and disposal cancels pending UI work',
    (tester) async {
      final native = FakeSeekPlayer()..fail = true;
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(harness(player));
      var slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChangeStart!(const SliderValue.single(.8));
      slider.onChangeEnd!(const SliderValue.single(.8));
      await tester.pumpAndSettle();
      expect(find.text('Could not seek. Try again.'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value.value, .1);
      native.fail = false;
      native.pending = Completer<void>();
      slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChangeStart!(const SliderValue.single(.4));
      slider.onChangeEnd!(const SliderValue.single(.4));
      await tester.pumpWidget(const SizedBox.shrink());
      native.pending!.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await player.dispose();
    },
  );

  testWidgets(
    'cancelled drags do not seek and swapping players detaches old events',
    (tester) async {
      final a = FakeSeekPlayer();
      final b = FakeSeekPlayer();
      final first = Player(platformPlayer: a);
      final second = Player(platformPlayer: b);
      await tester.pumpWidget(harness(first));
      final rect = tester.getRect(find.byType(Slider));
      final gesture = await tester.startGesture(
        Offset(rect.left + rect.width * .1, rect.center.dy),
      );
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pump();
      expect(a.targets, isEmpty);
      await tester.pumpWidget(harness(second));
      a.position(const Duration(seconds: 80));
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value.value, .1);
      await tester.pumpWidget(const SizedBox.shrink());
      await first.dispose();
      await second.dispose();
    },
  );
}
