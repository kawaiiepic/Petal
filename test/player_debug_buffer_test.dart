import 'package:petal/app/petal_app.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/pages/player/overlay/player_controls.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/player_debug_overlay.dart';
import 'package:petal/pages/player/overlay/seek_buffer_track.dart';
import 'package:petal/pages/player/overlay/seek_slider.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DebugPlayer extends PlatformPlayer {
  DebugPlayer() : super(configuration: const PlayerConfiguration());
  void buffered(Duration buffer) {
    state = state.copyWith(buffer: buffer);
    bufferController.add(buffer);
  }

  void duration(Duration duration) {
    state = state.copyWith(duration: duration);
    durationController.add(duration);
  }
}

class DebugVideoController extends Fake implements VideoController {
  @override
  final Player player;
  DebugVideoController(this.player);
}

class DebugVideoState extends Fake implements VideoState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'DebugVideoState';
  @override
  final Video widget;
  DebugVideoState(Player player)
    : widget = Video(controller: DebugVideoController(player));
}

Widget panel(
  Player player,
  VoidCallback close, {
  double width = 420,
  double height = 450,
}) => ShadcnApp(
  home: Scaffold(
    child: Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: width,
        height: height,
        child: PlayerDebugOverlay(player: player, onClose: close),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'player info button opens, toggles and closes diagnostics while controls stay visible',
    (tester) async {
      final native = DebugPlayer();
      native.state = PlayerState(
        duration: const Duration(seconds: 100),
        playlist: Playlist([
          Media(
            'file:///tmp/video.mp4',
            extras: {'offline': true, 'title': 'Downloaded video'},
          ),
        ]),
      );
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(
        Sizer(
          builder: (_, _, _) => ShadcnApp(
            navigatorKey: PetalApp.rootNavigatorKey,
            home: Scaffold(
              child: SizedBox(
                width: 800,
                height: 500,
                child: PlayerControls(state: DebugVideoState(player)),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(LucideIcons.info));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PlayerDebugOverlay), findsOneWidget);
      await tester.tap(find.text('Playback diagnostics'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Playback diagnostics'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(native.state.position, Duration.zero);
      await tester.pump(const Duration(seconds: 4));
      expect(
        tester
            .widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first)
            .opacity,
        1,
      );
      await tester.tap(find.byIcon(LucideIcons.info));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PlayerDebugOverlay), findsNothing);
      await tester.tap(find.byIcon(LucideIcons.info));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PlayerDebugOverlay), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets(
    'diagnostics read live state and keep source credentials out of the panel',
    (tester) async {
      final native = DebugPlayer();
      native.state = PlayerState(
        playlist: Playlist([
          Media('https://example.invalid/video?token=secret'),
        ]),
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 100),
        buffer: const Duration(seconds: 60),
        bufferingPercentage: 100,
        videoParams: const VideoParams(
          w: 1920,
          h: 1080,
          pixelformat: 'yuv420p',
        ),
        track: const Track(
          video: VideoTrack('1', null, null),
          audio: AudioTrack('2', null, null),
        ),
        tracks: const Tracks(
          video: [VideoTrack('1', null, null, codec: 'h264', fps: 23.976)],
          audio: [AudioTrack('2', null, 'eng', codec: 'aac')],
        ),
        audioParams: const AudioParams(sampleRate: 48000, channels: 'stereo'),
      );
      final player = Player(platformPlayer: native);
      await tester.pumpWidget(panel(player, () {}));
      expect(find.text('Playback diagnostics'), findsOneWidget);
      expect(find.text('Network stream'), findsOneWidget);
      expect(find.text('1920 × 1080'), findsOneWidget);
      expect(find.text('h264'), findsOneWidget);
      expect(find.text('aac'), findsOneWidget);
      expect(find.text('23.976'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
      expect(find.text('50.0 s'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      native.state = native.state.copyWith(
        buffering: true,
        buffer: const Duration(seconds: 80),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Buffering'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await player.dispose();
    },
  );

  testWidgets(
    'compact offline diagnostics scroll and close without affecting playback',
    (tester) async {
      final native = DebugPlayer();
      native.state = PlayerState(
        playlist: Playlist([
          Media('file:///tmp/video.mp4', extras: {'offline': true}),
        ]),
      );
      final player = Player(platformPlayer: native);
      var closed = 0;
      await tester.pumpWidget(
        panel(player, () => closed++, width: 270, height: 150),
      );
      expect(find.text('Local file'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump(const Duration(milliseconds: 350));
      expect(closed, 1);
      expect(native.state.playing, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );

  testWidgets('buffer track updates immediately as native cache advances', (
    tester,
  ) async {
    final native = DebugPlayer();
    native.state = const PlayerState(
      duration: Duration(seconds: 100),
      position: Duration(seconds: 10),
      buffer: Duration(seconds: 20),
    );
    final player = Player(platformPlayer: native);
    await tester.pumpWidget(
      ShadcnApp(
        home: Scaffold(
          child: SizedBox(
            width: 400,
            child: SeekSlider(player: player, visible: true),
          ),
        ),
      ),
    );
    expect(
      tester.widget<SeekBufferTrack>(find.byType(SeekBufferTrack)).fraction,
      .2,
    );
    native.buffered(const Duration(seconds: 75));
    await tester.pump();
    expect(
      tester.widget<SeekBufferTrack>(find.byType(SeekBufferTrack)).fraction,
      .75,
    );
    native.buffered(const Duration(seconds: 30));
    await tester.pump();
    expect(
      tester.widget<SeekBufferTrack>(find.byType(SeekBufferTrack)).fraction,
      .3,
    );
    native.duration(Duration.zero);
    await tester.pump();
    expect(
      tester.widget<SeekBufferTrack>(find.byType(SeekBufferTrack)).fraction,
      0,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await player.dispose();
  });

  testWidgets('buffer layer is visible, clamped and ignores pointer input', (
    tester,
  ) async {
    for (final (input, expected) in [
      (1.5, 1.0),
      (-.5, 0.0),
      (double.nan, 0.0),
      (.6, .6),
    ]) {
      await tester.pumpWidget(
        ShadcnApp(
          home: Scaffold(
            child: SizedBox(
              width: 300,
              height: 16,
              child: SeekBufferTrack(fraction: input),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        expected,
      );
      final colors = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((box) => box.color)
          .toSet();
      expect(colors, contains(Colors.white.withValues(alpha: .55)));
      expect(colors, contains(Colors.white.withValues(alpha: .12)));
      expect(
        find.ancestor(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
