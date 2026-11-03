import 'package:petal/pages/player/stream_player.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/home_layout.dart';
import 'package:petal/api/playback_preferences.dart';
import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/utils/byte_format.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/recording_adapter.dart';

class FeaturePaths extends PathProviderPlatform {
  final String path;
  FeaturePaths(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class PreferencePlayer extends PlatformPlayer {
  PreferencePlayer() : super(configuration: const PlayerConfiguration());
  @override
  Future<void> setRate(double rate) async {
    state = state.copyWith(rate: rate);
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    state = state.copyWith(track: Track(subtitle: track));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final adapter = RecordingAdapter();
  late Directory root;
  setUpAll(() async {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
    root = await Directory.systemTemp.createTemp('petal-features-');
    PathProviderPlatform.instance = FeaturePaths(root.path);
  });
  tearDownAll(() => root.delete(recursive: true));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    BackendApi.authState.setLoggedIn(null);
    await BackendCache.fetchWatchHistory();
    adapter.requests.clear();
    adapter.respond = (_) => jsonBody({'result': []});
  });
  void login(String profile) {
    BackendApi.authState.setLoggedIn({'id': 'user'});
    BackendApi.authState.setProfile(
      Profile(id: profile, userId: 'user', name: profile, createdAt: ''),
    );
  }

  test(
    'playback preferences persist languages, speed, delay and subtitle-off',
    () async {
      final prefs = PlaybackPreferences();
      await prefs.update(
        audio: 'ja',
        subtitle: 'fr',
        enabled: false,
        rate: 1.5,
        delay: -.75,
      );
      final reload = PlaybackPreferences();
      await reload.load();
      expect(reload.audioLanguage, 'ja');
      expect(reload.subtitleLanguage, 'fr');
      expect(reload.speed, 1.5);
      expect(reload.subtitleDelay, -.75);
      expect(reload.subtitles, isFalse);
      final native = PreferencePlayer();
      final player = Player(platformPlayer: native);
      await reload.apply(player);
      expect(player.state.rate, 1.5);
      expect(player.state.track.subtitle.id, 'no');
      await player.dispose();
    },
  );
  test(
    'concurrent preference loads wait for saved data and newer edits win',
    () async {
      SharedPreferences.setMockInitialValues({
        'player.preferences': jsonEncode({
          'audio': 'ko',
          'subtitle': 'en',
          'speed': 1.75,
          'delay': 2,
        }),
      });
      final prefs = PlaybackPreferences();
      await Future.wait([prefs.load(), prefs.load()]);
      expect(prefs.speed, 1.75);
      final next = PlaybackPreferences();
      final loading = next.load();
      await next.update(audio: 'de', rate: 2);
      await loading;
      expect(next.audioLanguage, 'de');
      expect(next.speed, 2);
    },
  );
  test('invalid playback values are clamped without storing NaN', () async {
    final prefs = PlaybackPreferences();
    await prefs.update(rate: 40, delay: -100);
    expect(prefs.speed, 3);
    expect(prefs.subtitleDelay, -60);
    await prefs.update(rate: double.nan, delay: double.infinity);
    expect(prefs.speed, 3);
    expect(prefs.subtitleDelay, -60);
  });
  test('preferred track languages match ISO aliases and regional codes', () {
    final state = StreamPlayerState();
    const tracks = [
      AudioTrack('1', 'English', 'eng'),
      AudioTrack('2', 'French', 'fr'),
    ];
    for (final preferred in ['fr', 'fra', 'fr-CA']) {
      final track = state.pickTrack<AudioTrack>(
        tracks: tracks,
        preferred: preferred,
        language: (t) => t.language,
        title: (t) => t.title,
      );
      expect(track?.id, '2');
    }
  });

  test(
    'Home layout hides redundant Start now and persists hide/reorder changes',
    () async {
      final layout = HomeLayout();
      await layout.load();
      expect(layout.hidden, contains('start'));
      final before = layout.order.indexOf('deck');
      await layout.move('deck', 1);
      await layout.setVisible('calendar', false);
      final restored = HomeLayout();
      await restored.load();
      expect(restored.order.indexOf('deck'), before + 1);
      expect(restored.hidden, contains('calendar'));
      await restored.reset();
      expect(restored.order, HomeLayout.labels.keys.toList());
      expect(restored.hidden, {'start'});
    },
  );
  test(
    'Home layout ignores unknown/duplicate IDs and preserves new sections',
    () async {
      SharedPreferences.setMockInitialValues({
        'home.layout': jsonEncode({
          'order': ['deck', 'bad', 'deck'],
          'hidden': ['bad', 'liked'],
        }),
      });
      final layout = HomeLayout();
      await layout.load();
      expect(layout.order.first, 'deck');
      expect(layout.order.length, HomeLayout.labels.length);
      expect(layout.hidden, {'liked'});
    },
  );
  test('sync is opt-in and recording never contacts the backend', () async {
    final sync = OfflineProgressSync();
    await sync.record(profileKey: 'user:a', mediaId: 42, completion: .5);
    expect(sync.pending, 0);
    expect(adapter.requests, isEmpty);
    await sync.setEnabled(true);
    await sync.record(
      profileKey: 'user:a',
      mediaId: 42,
      season: 1,
      episode: 2,
      completion: .95,
    );
    expect(sync.pending, 1);
    expect(adapter.requests, isEmpty);
    final reload = OfflineProgressSync();
    await reload.load();
    expect(reload.pending, 1);
    await reload.setEnabled(false);
    expect(reload.pending, 0);
  });
  test(
    'offline playback suspension and mismatched profiles cannot upload',
    () async {
      final sync = OfflineProgressSync();
      await sync.setEnabled(true);
      await sync.record(profileKey: 'user:a', mediaId: 42, completion: .5);
      login('b');
      await sync.sync();
      expect(adapter.requests, isEmpty);
      expect(sync.pending, 1);
      login('a');
      sync.suspend();
      await sync.sync();
      expect(adapter.requests, isEmpty);
      sync.resume();
      await sync.sync();
      expect(sync.pending, 0);
      expect(adapter.requests.where((r) => r.method == 'PUT').length, 1);
    },
  );
  test(
    'sync keeps failed uploads and retries at the 90 percent threshold',
    () async {
      final sync = OfflineProgressSync();
      await sync.setEnabled(true);
      await sync.record(
        profileKey: 'user:a',
        mediaId: 42,
        season: 2,
        episode: 3,
        completion: .9,
      );
      login('a');
      adapter.respond = (_) => throw StateError('Offline');
      await sync.sync();
      expect(sync.pending, 1);
      expect(sync.lastError, isNotNull);
      adapter.requests.clear();
      adapter.respond = (_) => jsonBody({'result': []});
      await sync.sync();
      expect(sync.pending, 0);
      final request = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(request.data['completion'], 1);
      expect(request.data['season'], 2);
      expect(request.data['episode'], 3);
    },
  );
  test('sync never overwrites farther-ahead remote progress', () async {
    final sync = OfflineProgressSync();
    await sync.setEnabled(true);
    await sync.record(profileKey: 'user:a', mediaId: 42, completion: .3);
    login('a');
    adapter.respond = (_) => jsonBody({
      'result': [
        {'tmdb_id': 42, 'media_type': 'movie', 'completion': .8},
      ],
    });
    await sync.sync();
    expect(sync.pending, 0);
    expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
  });
  test(
    'sync only acknowledges the uploaded revision and retains a newer edit',
    () async {
      final sync = OfflineProgressSync();
      await sync.setEnabled(true);
      await sync.record(profileKey: 'user:a', mediaId: 42, completion: .2);
      login('a');
      final pending = Completer<ResponseBody>();
      adapter.respond = (request) =>
          request.method == 'PUT' ? pending.future : jsonBody({'result': []});
      final sending = sync.sync();
      while (!adapter.requests.any((r) => r.method == 'PUT')) {
        await Future<void>.delayed(Duration.zero);
      }
      await sync.record(profileKey: 'user:a', mediaId: 42, completion: .6);
      pending.complete(jsonBody({'result': []}));
      await sending;
      expect(sync.pending, 1);
    },
  );
  test('download byte counts round-trip and legacy data stays readable', () {
    final entry = DownloadEntry(
      id: 'movie-42',
      title: 'Title',
      tmdbId: 42,
      downloadedBytes: 256,
      totalBytes: 1024,
    );
    final restored = DownloadEntry.fromJson(entry.toJson());
    expect(restored.downloadedBytes, 256);
    expect(restored.totalBytes, 1024);
    expect(DownloadEntry.fromJson({'id': 'legacy'}).totalBytes, 0);
    expect(formatBytes(1024), '1.0 KB');
    expect(formatBytes(1024 * 1024 * 3), '3.0 MB');
  });
  test(
    'storage summary counts media files and fills old download sizes',
    () async {
      final dir = Directory('${root.path}/downloads');
      await dir.create();
      final file = File('${dir.path}/movie.mp4');
      await file.writeAsBytes(List.filled(2048, 0));
      await File('${dir.path}/index.json').writeAsString('[]');
      final entry = DownloadEntry(
        id: 'movie-42',
        title: 'Title',
        tmdbId: 42,
        path: file.path,
        status: DownloadStatus.done,
      );
      DownloadManager.items.value = [entry];
      final summary = await DownloadManager.storage();
      expect(summary.usedBytes, 2048);
      expect(entry.totalBytes, 2048);
      if (summary.freeBytes != null) expect(summary.freeBytes, greaterThan(0));
    },
  );
  test(
    'failed local downloads can retry to completion without backend requests',
    () async {
      final input = File('${root.path}/retry-input.mp4');
      final entry = DownloadEntry(
        id: 'movie-99',
        title: 'Retry',
        tmdbId: 99,
        url: input.uri.toString(),
        status: DownloadStatus.failed,
      );
      DownloadManager.items.value = [entry];
      Future<void> waitForJob() async {
        final until = DateTime.now().add(const Duration(seconds: 3));
        while ((entry.status == DownloadStatus.queued ||
                entry.status == DownloadStatus.running) &&
            DateTime.now().isBefore(until)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      }

      await DownloadManager.retry(entry.id);
      await waitForJob();
      expect(entry.status, DownloadStatus.failed);
      await input.writeAsBytes(List.filled(4096, 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await DownloadManager.retry(entry.id);
      await waitForJob();
      expect(entry.status, DownloadStatus.done);
      expect(entry.totalBytes, 4096);
      expect(adapter.requests, isEmpty);
      await DownloadManager.remove(entry.id);
      expect(await File(entry.path!).exists(), isFalse);
    },
  );
}
