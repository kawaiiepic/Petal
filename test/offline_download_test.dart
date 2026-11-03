import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/api/playback_source.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';

import 'support/recording_adapter.dart';

class TestPaths extends PathProviderPlatform {
  final String root;
  TestPaths(this.root);
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  final adapter = RecordingAdapter();
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('petal-offline-test-');
    PathProviderPlatform.instance = TestPaths(root.path);
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
    adapter.respond = (_) =>
        throw StateError('Network forbidden during offline playback');
  });
  tearDownAll(() async {
    await root.delete(recursive: true);
  });

  test('saved labels and local resume progress survive serialization', () {
    final entry = DownloadEntry(
      id: 'show-42-1-2',
      title: 'legacy label',
      tmdbId: 42,
      season: 1,
      episode: 2,
      mediaTitle: 'Example Show',
      episodeTitle: 'The second episode',
      playbackProgress: 0.4,
    );
    final restored = DownloadEntry.fromJson(entry.toJson());
    expect(restored.displayTitle, 'Example Show');
    expect(restored.episodeLabel, 'S01E02 · The second episode');
    expect(restored.playbackProgress, 0.4);
    expect(
      DownloadEntry.fromJson({
        'id': 'old',
        'tmdbId': 42,
        'title': 'Old download',
      }).displayTitle,
      'Old download',
    );
  });

  test('an explicit downloaded source resolves without backend or metadata requests', () async {
    final local = StreamItem.localFile(
      path: '${root.path}/episode with spaces.mp4',
      title: 'Example Show',
    );
    final resolved = await PlaybackSource.resolve(
      mediaId: 42,
      episode: Episode(seasonNumber: 1, episodeNumber: 2),
      selected: local,
    );
    expect(identical(local, resolved), isTrue);
    expect(local.isLocal, isTrue);
    expect(
      Uri.parse(local.url).toFilePath(),
      '${root.path}/episode with spaces.mp4',
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'local progress is saved to disk, and deleting a download deletes the file',
    () async {
      final source = File('${root.path}/source with spaces.mp4');
      await source.writeAsBytes([1, 2, 3, 4]);
      await DownloadManager.enqueueStream(
        stream: StreamItem.localFile(path: source.path, title: 'Example'),
        tmdbId: 42,
        title: 'Example Show',
        season: 1,
        episode: 2,
        mediaTitle: 'Example Show',
        episodeTitle: 'Second episode',
      );
      DownloadEntry? entry;
      for (var i = 0; i < 100; i++) {
        entry = DownloadManager.find(tmdbId: 42, season: 1, episode: 2);
        if (entry?.status == DownloadStatus.done ||
            entry?.status == DownloadStatus.failed)
          break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(entry!.status, DownloadStatus.done);
      expect(await File(entry.path!).readAsBytes(), [1, 2, 3, 4]);
      await DownloadManager.setPlaybackProgress(entry.id, 0.4);
      final rows = jsonDecode(
        await File('${root.path}/downloads/index.json').readAsString(),
      ) as List;
      expect(rows.single['playbackProgress'], 0.4);
      expect(rows.single['episodeTitle'], 'Second episode');
      await DownloadManager.remove(entry.id);
      expect(await File(entry.path!).exists(), isFalse);
      expect(DownloadManager.items.value, isEmpty);
      expect(adapter.requests, isEmpty);
    },
  );
}
