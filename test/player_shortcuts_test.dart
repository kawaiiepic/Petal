import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/pages/player/overlay/player_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class FeaturePlayer extends PlatformPlayer {
  final seeks = <Duration>[];
  FeaturePlayer() : super(configuration: const PlayerConfiguration()) {
    state = PlayerState(
      position: const Duration(seconds: 20),
      duration: const Duration(seconds: 100),
      playlist: Playlist([
        Media(
          'file:///video.mp4',
          extras: {'offline': true, 'title': 'Local video'},
        ),
      ]),
    );
  }
  @override
  Future<void> playOrPause() async {
    state = state.copyWith(playing: !state.playing);
    playingController.add(state.playing);
  }

  @override
  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    volumeController.add(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    state = state.copyWith(rate: rate);
    rateController.add(rate);
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    state = state.copyWith(track: Track(subtitle: track));
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    state = state.copyWith(position: position);
    positionController.add(position);
  }
}

class FeatureController extends Fake implements VideoController {
  @override
  final Player player;
  FeatureController(this.player);
}

class FeatureVideoState extends Fake implements VideoState {
  @override
  final Video widget;
  bool fullscreen = false;
  int toggles = 0;
  FeatureVideoState(Player player)
    : widget = Video(controller: FeatureController(player));
  @override
  bool isFullscreen() => fullscreen;
  @override
  Future<void> toggleFullscreen() async {
    fullscreen = !fullscreen;
    toggles++;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FeatureVideoState';
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets(
    'desktop shortcuts control playback, seek, volume, mute, speed and fullscreen',
    (tester) async {
      final native = FeaturePlayer();
      final player = Player(platformPlayer: native);
      final video = FeatureVideoState(player);
      await tester.pumpWidget(
        Sizer(
          builder: (_, _, _) => ShadcnApp(
            navigatorKey: PetalApp.rootNavigatorKey,
            home: Scaffold(
              child: SizedBox(
                width: 800,
                height: 500,
                child: PlayerControls(state: video),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(player.state.playing, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(player.state.playing, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(native.seeks.last, const Duration(seconds: 30));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      expect(native.seeks.last, const Duration(seconds: 20));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(player.state.volume, 95);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(player.state.volume, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(player.state.volume, 95);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.pump();
      expect(player.state.rate, 1.25);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(player.state.track.subtitle.id, 'no');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();
      expect(video.fullscreen, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(video.fullscreen, isFalse);
      expect(video.toggles, 2);
      final before = native.seeks.length;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(native.seeks.length, before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );
}
