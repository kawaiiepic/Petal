import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/pages/player/overlay/next_up_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class NextPlayer extends PlatformPlayer {
  NextPlayer() : super(configuration: const PlayerConfiguration()) {
    state = const PlayerState(
      position: Duration(seconds: 94),
      duration: Duration(seconds: 100),
      playing: true,
    );
  }
  void position(int seconds) {
    state = state.copyWith(position: Duration(seconds: seconds));
    positionController.add(state.position);
  }

  void playing(bool value) {
    state = state.copyWith(playing: value);
    playingController.add(value);
  }

  void complete() {
    state = state.copyWith(
      position: const Duration(seconds: 100),
      playing: false,
      completed: true,
    );
    completedController.add(true);
    playingController.add(false);
  }

  void buffering(bool value) {
    state = state.copyWith(buffering: value);
    bufferingController.add(value);
  }
}

TmdbEpisode episode(int number) => TmdbEpisode.fromJson({
  'id': number,
  'name': 'The next episode',
  'season_number': 2,
  'episode_number': number,
});
Widget harness(
  Player player,
  Future<TmdbEpisode?> future,
  VoidCallback play, {
  bool suppressed = false,
  double width = 320,
}) => ShadcnApp(
  home: Scaffold(
    child: Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: width,
        child: NextUpCard(
          player: player,
          nextEpisode: future,
          playNextEpisode: play,
          suppressed: suppressed,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('thumbnail stays 16:9 on narrow and wide layouts', (
    tester,
  ) async {
    final native = NextPlayer();
    final player = Player(platformPlayer: native);
    final future = Future.value(episode(3));
    for (final width in [240.0, 320.0]) {
      await tester.pumpWidget(harness(player, future, () {}, width: width));
      await tester.pump();
      final size = tester.getSize(find.byType(AspectRatio));
      expect(size.width / size.height, closeTo(16 / 9, .001));
      expect(size.width, width);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await player.dispose();
  });

  testWidgets(
    'close dismisses the card and cancels autoplay for the current episode',
    (tester) async {
      final native = NextPlayer();
      final player = Player(platformPlayer: native);
      var plays = 0;
      final future = Future.value(episode(3));
      await tester.pumpWidget(harness(player, future, () => plays++));
      await tester.pump();
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Up next'), findsNothing);
      native.position(50);
      await tester.pump();
      native.position(96);
      await tester.pump();
      await tester.pumpWidget(
        harness(player, future, () => plays++, suppressed: true),
      );
      await tester.pumpWidget(harness(player, future, () => plays++));
      await tester.pump(const Duration(seconds: 60));
      expect(plays, 0);
      expect(find.text('Up next'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'countdown pauses during pause or buffering and only plays once',
    (tester) async {
      final native = NextPlayer();
      final player = Player(platformPlayer: native);
      var plays = 0;
      await tester.pumpWidget(
        harness(player, Future.value(episode(3)), () => plays++),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Play next in 40 s'), findsOneWidget);
      native.playing(false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
      expect(plays, 0);
      native.buffering(true);
      native.playing(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Play next in 40 s'), findsOneWidget);
      native.buffering(false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 40));
      expect(plays, 1);
      await tester.pump(const Duration(seconds: 60));
      expect(plays, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'no countdown runs without resolved metadata, or while panel is suppressed',
    (tester) async {
      final native = NextPlayer();
      final player = Player(platformPlayer: native);
      final pending = Completer<TmdbEpisode?>();
      var plays = 0;
      await tester.pumpWidget(harness(player, pending.future, () => plays++));
      await tester.pump(const Duration(seconds: 60));
      expect(plays, 0);
      pending.complete(episode(3));
      await tester.pump();
      await tester.pumpWidget(
        harness(player, pending.future, () => plays++, suppressed: true),
      );
      await tester.pump(const Duration(seconds: 60));
      expect(plays, 0);
      expect(find.text('Up next'), findsNothing);
      await tester.pumpWidget(harness(player, pending.future, () => plays++));
      await tester.pump();
      expect(find.text('Play next in 45 s'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'seeking away resets countdown and a new episode clears dismissal',
    (tester) async {
      final native = NextPlayer();
      final player = Player(platformPlayer: native);
      var plays = 0;
      final future = Future.value(episode(3));
      await tester.pumpWidget(harness(player, future, () => plays++));
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      native.position(20);
      await tester.pump();
      expect(find.text('Up next'), findsNothing);
      native.position(94);
      await tester.pump();
      expect(find.text('Play next in 45 s'), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpWidget(
        harness(player, Future.value(episode(4)), () => plays++),
      );
      await tester.pump();
      expect(find.textContaining('S2 · E4'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 60));
      expect(plays, 0);
      await player.dispose();
    },
  );

  testWidgets('autoplay countdown can finish after playback reaches EOF', (
    tester,
  ) async {
    final native = NextPlayer();
    final player = Player(platformPlayer: native);
    var plays = 0;
    await tester.pumpWidget(
      harness(player, Future.value(episode(3)), () => plays++),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    native.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(plays, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await player.dispose();
  });

  testWidgets('manual play cancels the countdown instead of playing twice', (
    tester,
  ) async {
    final native = NextPlayer();
    final player = Player(platformPlayer: native);
    var plays = 0;
    await tester.pumpWidget(
      harness(player, Future.value(episode(3)), () => plays++),
    );
    await tester.pump();
    await tester.tap(find.textContaining('S2 · E3'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(plays, 1);
    await tester.pump(const Duration(seconds: 60));
    expect(plays, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await player.dispose();
  });
}
