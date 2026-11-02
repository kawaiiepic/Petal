import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/resumable_download.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:petal/api/playback_preferences.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/models/media_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/recording_adapter.dart';

class QueuePaths extends PathProviderPlatform {
  final String path;
  QueuePaths(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late File file;
  late RecordingAdapter adapter;
  late Dio dio;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('petal-resume-');
    PathProviderPlatform.instance = QueuePaths(root.path);
    file = File('${root.path}/video.mp4');
    adapter = RecordingAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  Future<void> download({
    String? previous,
    CancelToken? cancel,
    void Function(int, int)? progress,
  }) => ResumableDownload.run(
    dio: dio,
    url: 'https://media.test/video',
    file: file,
    cancelToken: cancel ?? CancelToken(),
    previousValidator: previous,
    validator: (_) {},
    progress: progress ?? (_, _) {},
  );
  ResponseBody bytes(
    List<int> data,
    int status,
    Map<String, List<String>> headers,
  ) => ResponseBody(
    Stream.value(Uint8List.fromList(data)),
    status,
    headers: headers,
  );

  test('range resume appends only the requested bytes', () async {
    await file.writeAsBytes([1, 2]);
    adapter.respond = (request) {
      expect(request.headers['Range'], 'bytes=2-');
      expect(request.headers['If-Range'], '"version1"');
      return bytes(
        [3, 4],
        206,
        {
          'content-range': ['bytes 2-3/4'],
          'etag': ['"version1"'],
        },
      );
    };
    await download(previous: '"version1"');
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });
  test(
    'range unsupported restarts instead of corrupting partial file',
    () async {
      await file.writeAsBytes([9, 9]);
      adapter.respond = (_) => bytes(
        [1, 2, 3],
        200,
        {
          'content-length': ['3'],
        },
      );
      await download(previous: '"old"');
      expect(await file.readAsBytes(), [1, 2, 3]);
    },
  );
  test('changed validator requests a fresh full file', () async {
    await file.writeAsBytes([9, 9]);
    adapter.respond = (request) => request.headers.containsKey('Range')
        ? bytes(
            [3, 4],
            206,
            {
              'content-range': ['bytes 2-3/4'],
              'etag': ['"new"'],
            },
          )
        : bytes(
            [1, 2, 3, 4],
            200,
            {
              'content-length': ['4'],
              'etag': ['"new"'],
            },
          );
    await download(previous: '"old"');
    expect(adapter.requests.length, 2);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });
  test('invalid range leaves partial file unchanged', () async {
    await file.writeAsBytes([1, 2]);
    adapter.respond = (_) => bytes(
      [4],
      206,
      {
        'content-range': ['bytes 3-3/4'],
      },
    );
    await expectLater(download(previous: '"old"'), throwsStateError);
    expect(await file.readAsBytes(), [1, 2]);
  });
  test(
    'already complete range is accepted only with matching validator',
    () async {
      await file.writeAsBytes([1, 2]);
      adapter.respond = (_) => bytes([], 416, {
        'content-range': ['bytes */2'],
        'etag': ['"v1"'],
      });
      await download(previous: '"v1"');
      expect(await file.readAsBytes(), [1, 2]);
    },
  );
  test(
    'truncated responses fail instead of marking incomplete files done',
    () async {
      adapter.respond = (_) => bytes(
        [1, 2],
        200,
        {
          'content-length': ['4'],
          'etag': ['"v1"'],
        },
      );
      await expectLater(download(), throwsStateError);
      expect(await file.readAsBytes(), [1, 2]);
    },
  );
  test('cancelling transfer retains received partial bytes', () async {
    final token = CancelToken();
    adapter.respond = (_) => ResponseBody(
      Stream<Uint8List>.fromIterable([
        Uint8List.fromList([1, 2]),
        Uint8List.fromList([3, 4]),
      ]),
      200,
      headers: {
        'content-length': ['4'],
      },
    );
    await expectLater(
      download(
        cancel: token,
        progress: (count, total) {
          if (count == 2) token.cancel('pause');
        },
      ),
      throwsA(isA<DioException>()),
    );
    expect(await file.readAsBytes(), [1, 2]);
  });
  test('subtitle appearance persists and invalid sizes remain safe', () async {
    final p = PlaybackPreferences();
    await p.update(size: 42, outline: 3, bottom: 90, background: false);
    final restored = PlaybackPreferences();
    await restored.load();
    expect(restored.subtitleSize, 42);
    expect(restored.subtitleOutline, 3);
    expect(restored.subtitleBottom, 90);
    expect(restored.subtitleBackground, false);
    await restored.update(size: double.nan, outline: 100, bottom: -100);
    expect(restored.subtitleSize, 32);
    expect(restored.subtitleOutline, 6);
    expect(restored.subtitleBottom, 0);
  });
  test(
    'manual reset and undo target exact episode and original profile',
    () async {
      BackendApi.dio = dio;
      BackendApi.authState.setLoggedIn({'id': 'u'});
      BackendApi.authState.setProfile(
        Profile(id: 'p', userId: 'u', name: 'p', createdAt: ''),
      );
      double remote = .6;
      adapter.respond = (r) {
        if (r.method == 'PUT')
          remote = (r.data['completion'] as num).toDouble();
        return jsonBody({
          'result': r.path.contains('/states/')
              ? [
                  {
                    'tmdb_id': 42,
                    'media_type': 'show',
                    'updated_at': 1,
                    'episodes': [
                      {'season': 2, 'episode': 3, 'completion': remote},
                    ],
                  },
                ]
              : [],
        });
      };
      await HistoryActions.setProgress(
        42,
        MediaType.show,
        0,
        season: 2,
        episode: 3,
      );
      final put = adapter.requests.where((r) => r.method == 'PUT').last;
      expect(put.path, contains('/track/state/p/episode/42'));
      expect(put.data, containsPair('season', 2));
      expect(put.data, containsPair('episode', 3));
      expect(put.data, containsPair('completion', 0));
      await HistoryActions.undo();
      expect(
        adapter.requests.where((r) => r.method == 'PUT').last.data,
        containsPair('completion', .6),
      );
      await HistoryActions.setProgress(
        42,
        MediaType.show,
        1,
        season: 2,
        episode: 3,
      );
      BackendApi.authState.setProfile(
        Profile(id: 'other', userId: 'u', name: 'other', createdAt: ''),
      );
      final count = adapter.requests.where((r) => r.method == 'PUT').length;
      await expectLater(HistoryActions.undo(), throwsStateError);
      expect(adapter.requests.where((r) => r.method == 'PUT').length, count);
    },
  );
  test('reset discards pending offline progress for only its target', () async {
    final sync = OfflineProgressSync();
    await sync.load();
    // Load a persisted queue without starting uploads.
    sync.dispose();
    SharedPreferences.setMockInitialValues({
      'offline.sync.enabled': true,
      'offline.sync.queue': jsonEncode({
        'p|42|2|3': {
          'profile': 'p',
          'media': 42,
          'season': 2,
          'episode': 3,
          'completion': .5,
          'at': 1,
          'revision': 1,
        },
        'p|42|2|4': {
          'profile': 'p',
          'media': 42,
          'season': 2,
          'episode': 4,
          'completion': .5,
          'at': 1,
          'revision': 2,
        },
      }),
    });
    final queued = OfflineProgressSync();
    await queued.load();
    await queued.discard(profileKey: 'p', mediaId: 42, season: 2, episode: 3);
    expect(queued.pending, 1);
    queued.dispose();
  });
  test(
    'queue controls pause and reorder without losing partial files',
    () async {
      final partial = File('${root.path}/partial.mp4');
      await partial.writeAsBytes([1, 2]);
      final a = DownloadEntry(
        id: 'a',
        title: 'A',
        tmdbId: 1,
        path: partial.path,
        downloadedBytes: 2,
        validator: '"v1"',
      );
      final b = DownloadEntry(id: 'b', title: 'B', tmdbId: 2);
      final c = DownloadEntry(id: 'c', title: 'C', tmdbId: 3);
      DownloadManager.items.value = [a, b, c];
      await DownloadManager.moveEarlier('c');
      expect(DownloadManager.items.value.map((e) => e.id), ['a', 'c', 'b']);
      await DownloadManager.pause('a');
      expect(a.status, DownloadStatus.paused);
      expect(await partial.readAsBytes(), [1, 2]);
      final restored = DownloadEntry.fromJson(a.toJson());
      expect(restored.status, DownloadStatus.paused);
      expect(restored.validator, '"v1"');
      expect(restored.downloadedBytes, 2);
      DownloadManager.items.value = [];
    },
  );
}
