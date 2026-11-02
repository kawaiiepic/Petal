import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/playback_media_session.dart';
import 'package:petal/api/playback_volume_store.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/pages/player/overlay/player_controls.dart';
import 'package:petal/pages/player/playback_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

import 'support/recording_adapter.dart';

class SessionPlayer extends PlatformPlayer {
  final opened = <Media>[];
  final events = <String>[];
  Completer<void>? pending;
  bool fail = false;
  SessionPlayer() : super(configuration: const PlayerConfiguration());
  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    final media = playable as Media;
    opened.add(media);
    events.add('open:$play');
    await pending?.future;
    if (fail) throw StateError('Source failed');
    // Simulate a backend that resets its volume on every media open.
    state = PlayerState(
      playlist: Playlist([media]),
      duration: const Duration(seconds: 100),
      volume: 100,
      playing: play,
    );
    playlistController.add(state.playlist);
  }

  @override
  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    events.add('volume:$volume');
    volumeController.add(volume);
  }

  @override
  Future<void> play() async {
    events.add('play:${state.volume}');
    state = state.copyWith(playing: true);
    playingController.add(true);
  }
}

class SessionVideoController extends Fake implements VideoController {
  @override
  final Player player;
  SessionVideoController(this.player);
}

class SessionVideoState extends Fake implements VideoState {
  @override
  final Video widget;
  SessionVideoState(Player player)
    : widget = Video(controller: SessionVideoController(player));
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'SessionVideoState';
}

void main() {
  final adapter = RecordingAdapter();
  setUpAll(() {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({
      PlaybackVolumeStore.volumeKey: 35.0,
    });
    TMDB.clearCache();
    adapter.requests.clear();
  });

  test('device volume and mute survive a new store/session', () async {
    final store = PlaybackVolumeStore();
    expect(await store.load(), 35);
    await store.save(42);
    await store.save(0);
    final reloaded = PlaybackVolumeStore();
    expect(await reloaded.load(), 0);
    expect(reloaded.audibleVolume, 42);
    await reloaded.save(reloaded.audibleVolume);
    expect(await PlaybackVolumeStore().load(), 42);
  });

  test(
    'a late preference read cannot overwrite a newer user adjustment',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final pending = Completer<SharedPreferences>();
      final store = PlaybackVolumeStore(preferences: () => pending.future);
      final loading = store.load();
      final save = store.save(23);
      pending.complete(prefs);
      expect(await loading, 23);
      await save;
      expect(prefs.getDouble(PlaybackVolumeStore.volumeKey), 23);
    },
  );

  test(
    'queued writes finish with the latest volume and clamp invalid input',
    () async {
      final store = PlaybackVolumeStore();
      await Future.wait([store.save(10), store.save(50), store.save(19)]);
      expect(await PlaybackVolumeStore().load(), 19);
      await store.save(200);
      expect(store.value, 100);
      await store.save(-5);
      expect(store.value, 0);
    },
  );

  test('successive episodes reuse the same player and restore volume before playing', () async {
    final native = SessionPlayer();
    final player = Player(platformPlayer: native);
    final session = PlaybackMediaSession(
      player,
      volumeStore: PlaybackVolumeStore(),
    );
    await session.open(Media('file:///episode1.mp4'));
    expect(native.events, ['open:false', 'volume:35.0', 'play:35.0']);
    await player.setVolume(42);
    native.events.clear();
    await session.open(
      Media('file:///episode2.mp4'),
      beforePlay: () async => native.events.add('ready'),
    );
    expect(identical(session.player, player), isTrue);
    expect(native.opened.length, 2);
    expect(native.events, ['open:false', 'volume:42.0', 'ready', 'play:42.0']);
    await player.dispose();
  });

  test(
    'a volume change during source opening wins over the initial volume',
    () async {
      final native = SessionPlayer()..pending = Completer<void>();
      final player = Player(platformPlayer: native);
      final store = PlaybackVolumeStore();
      final session = PlaybackMediaSession(player, volumeStore: store);
      final opening = session.open(Media('file:///episode1.mp4'));
      // Let preference load and source opening start.
      while (native.opened.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await store.save(17);
      native.pending!.complete();
      await opening;
      expect(player.state.volume, 17);
      expect(native.events.last, 'play:17.0');
      await player.dispose();
    },
  );

  test(
    'a failed open can retry and never starts playback at default volume',
    () async {
      final native = SessionPlayer()..fail = true;
      final player = Player(platformPlayer: native);
      final session = PlaybackMediaSession(
        player,
        volumeStore: PlaybackVolumeStore(),
      );
      await expectLater(
        session.open(Media('file:///episode1.mp4')),
        throwsStateError,
      );
      expect(
        native.events.where((event) => event.startsWith('play:')),
        isEmpty,
      );
      native.fail = false;
      await session.open(Media('file:///episode1.mp4'));
      expect(native.events.last, 'play:35.0');
      await player.dispose();
    },
  );

  testWidgets(
    'Next episode updates the existing controls and native player without navigation',
    (tester) async {
      adapter.respond = (request) {
        final path = request.queryParameters['url'] as String? ?? '';
        return jsonBody(
          path.contains('/episode/')
              ? {
                  'id': 2,
                  'name': 'Second episode',
                  'season_number': 1,
                  'episode_number': 2,
                  'air_date': '2025-01-01',
                }
              : {
                  'id': 42,
                  'name': 'Example Show',
                  'seasons': [
                    {'id': 1, 'season_number': 1, 'episode_count': 3},
                  ],
                },
        );
      };
      final native = SessionPlayer();
      native.state = PlayerState(
        playlist: Playlist([
          Media(
            'https://example.invalid/episode1',
            extras: {
              'mediaId': 42,
              'episode': Episode(seasonNumber: 1, episodeNumber: 1),
            },
          ),
        ]),
        duration: const Duration(seconds: 100),
      );
      final player = Player(platformPlayer: native);
      final session = PlaybackMediaSession(
        player,
        volumeStore: PlaybackVolumeStore(),
      );
      final requests = <Episode>[];
      await tester.pumpWidget(
        Sizer(
          builder: (_, _, _) => ShadcnApp(
            navigatorKey: PetalApp.rootNavigatorKey,
            home: Scaffold(
              child: PlaybackScope(
                playEpisode: (episode) async {
                  requests.add(episode);
                  await session.open(
                    Media(
                      'file:///episode2',
                      extras: {
                        'mediaId': 42,
                        'episode': episode,
                        'offline': true,
                        'title': 'Second episode',
                      },
                    ),
                  );
                },
                child: SizedBox(
                  width: 800,
                  height: 500,
                  child: PlayerControls(state: SessionVideoState(player)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      final state = tester.state(find.byType(PlayerControls));
      await tester.tap(find.byIcon(LucideIcons.skipForward));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 200));
      expect(requests.length, 1);
      expect(requests.single.seasonNumber, 1);
      expect(requests.single.episodeNumber, 2);
      expect(
        identical(tester.state(find.byType(PlayerControls)), state),
        isTrue,
      );
      expect(identical(session.player, player), isTrue);
      expect(player.state.volume, 35);
      expect(find.text('Second episode'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await player.dispose();
    },
  );
}
