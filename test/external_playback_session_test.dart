import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/external_playback_session.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/external_playback_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ExternalPlaybackSession session;
  var profile = 'a';
  var prompts = 0;
  bool? answer;
  final watched = <ExternalPlaybackRequest>[];
  final request = ExternalPlaybackRequest(
    mediaId: 42,
    episode: Episode(seasonNumber: 1, episodeNumber: 2),
    label: 'Example episode',
    profileKey: 'a',
  );
  setUp(() {
    prompts = 0;
    profile = 'a';
    answer = true;
    watched.clear();
    session = ExternalPlaybackSession(
      profileKey: () => profile,
      confirm: (_) async {
        prompts++;
        return answer;
      },
      markWatched: (request) async => watched.add(request),
    );
  });
  tearDown(() => session.dispose());
  Future<void> flush() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }

  test('launch and foreground events alone never mark watched', () async {
    expect(
      await session.begin(request: request, open: () async => true),
      isTrue,
    );
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(prompts, 0);
    expect(watched, isEmpty);
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(prompts, 1);
    expect(watched.single.episode!.episodeNumber, 2);
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(prompts, 1);
  });

  test('declining completion leaves watched state unchanged', () async {
    answer = false;
    await session.begin(request: request, open: () async => true);
    session.didChangeAppLifecycleState(AppLifecycleState.inactive);
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(prompts, 1);
    expect(watched, isEmpty);
  });

  test('lifecycle may return before launch future completes', () async {
    final launched = Completer<bool>();
    final opening = session.begin(
      request: request,
      open: () => launched.future,
    );
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(prompts, 0);
    launched.complete(true);
    await opening;
    await flush();
    expect(prompts, 1);
    expect(watched.length, 1);
  });

  test(
    'failed launch and changed profile cannot mark an episode watched',
    () async {
      expect(
        await session.begin(request: request, open: () async => false),
        isFalse,
      );
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await flush();
      expect(prompts, 0);
      await session.begin(request: request, open: () async => true);
      profile = 'b';
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await flush();
      expect(prompts, 0);
      expect(watched, isEmpty);
    },
  );
}
