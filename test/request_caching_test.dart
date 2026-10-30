import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/backend/library_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/profile.dart';

import 'support/recording_adapter.dart';

Profile profile(String id) =>
    Profile(id: id, userId: 'user', name: id, createdAt: '');

void main() {
  final adapter = RecordingAdapter();
  setUpAll(() {
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
  });
  setUp(() async {
    BackendApi.authState.setLoggedIn(null);
    await BackendCache.fetchWatchHistory();
    await LibraryApi.fetch();
    TMDB.clearCache();
    adapter.requests.clear();
    adapter.respond = null;
    BackendApi.authState.setLoggedIn({'id': 'user'});
    BackendApi.authState.setProfile(profile('a'));
  });

  test(
    'repeated title/logo lookups share one encoded metadata request',
    () async {
      adapter.respond = (_) => jsonBody({
        'id': 42,
        'images': {
          'logos': [
            {'file_path': '/title.png', 'iso_639_1': 'en', 'width': 600},
          ],
        },
      });
      await Future.wait([
        TMDB.tvShow(42),
        TMDB.titleLogo(42, MediaType.show),
        TMDB.tvShow(42),
      ]);
      expect(adapter.requests.length, 1);
      expect(
        await TMDB.titleLogo(42, MediaType.show),
        'https://image.tmdb.org/t/p/original/title.png',
      );
      expect(adapter.requests.length, 1);
      final query = adapter.requests.single.uri.queryParameters;
      expect(query.keys, contains('url'));
      expect(query['url'], contains('&include_image_language=en,null'));
      expect(query.keys, isNot(contains('include_image_language')));
    },
  );

  test(
    'failed metadata lookup is retried instead of cached permanently',
    () async {
      adapter.respond = (_) => jsonBody({}, status: 503);
      await expectLater(TMDB.tvShow(43), throwsA(isA<DioException>()));
      adapter.respond = (_) => jsonBody({'id': 43});
      expect((await TMDB.tvShow(43)).id, 43);
      expect(adapter.requests.length, 2);
    },
  );

  test('history and next-up share reads until explicitly refreshed', () async {
    await Future.wait([
      BackendCache.fetchWatchHistory(),
      BackendCache.fetchWatchHistory(),
      BackendCache.fetchContinueWatching(),
      BackendCache.fetchContinueWatching(),
    ]);
    await BackendCache.fetchWatchHistory();
    await BackendCache.fetchContinueWatching();
    expect(adapter.count('/track/states/'), 1);
    expect(adapter.count('/track/continue/'), 1);
    await BackendCache.fetchWatchHistory(force: true);
    expect(adapter.count('/track/states/'), 2);
  });

  test('progress writes invalidate history without refreshing every imported episode', () async {
    await BackendCache.fetchWatchHistory();
    await BackendApi.setProgress(
      42,
      MediaType.show,
      1,
      season: 1,
      episode: 1,
      refresh: false,
    );
    await BackendApi.setProgress(
      42,
      MediaType.show,
      1,
      season: 1,
      episode: 2,
      refresh: false,
    );
    expect(adapter.count('/track/continue/'), 0);
    await BackendCache.fetchWatchHistory();
    await BackendCache.fetchContinueWatching();
    expect(adapter.count('/track/states/'), 2);
    expect(adapter.count('/track/continue/'), 1);
  });

  test(
    'late profile response cannot overwrite the newly selected profile',
    () async {
      final old = Completer<ResponseBody>();
      adapter.respond = (request) => request.path.endsWith('/a')
          ? old.future
          : jsonBody({
              'result': [
                {'tmdb_id': 20, 'media_type': 'movie', 'completion': 0.5},
              ],
            });
      final first = BackendCache.fetchWatchHistory();
      BackendApi.authState.setProfile(profile('b'));
      await BackendCache.fetchWatchHistory();
      old.complete(
        jsonBody({
          'result': [
            {'tmdb_id': 10, 'media_type': 'movie', 'completion': 0.5},
          ],
        }),
      );
      await first;
      expect(BackendCache.watchHistory.value.single.tmdbId, 20);
      BackendApi.authState.setLoggedIn(null);
      await BackendCache.fetchWatchHistory();
      expect(BackendCache.watchHistory.value, isEmpty);
      expect(BackendApi.authState.selectedProfile, isNull);
    },
  );

  test('a profile switch during metadata lookup cannot write progress into the new profile', () async {
    final pending = Completer<ResponseBody>();
    adapter.respond = (request) => request.path.contains('/tmdb/proxy')
        ? pending.future
        : jsonBody({'result': []});
    final update = UserLibrary.toggleWatched(99, MediaType.show);
    BackendApi.authState.setProfile(profile('b'));
    pending.complete(
      jsonBody({
        'id': 99,
        'seasons': [
          {'id': 1, 'season_number': 1, 'episode_count': 2},
        ],
      }),
    );
    await update;
    expect(
      adapter.requests.where((request) => request.method == 'PUT'),
      isEmpty,
    );
  });

  test(
    'library reads are cached, invalidated by writes, and cleared on logout',
    () async {
      adapter.respond = (_) => jsonBody({
        'result': [
          {'tmdb_id': 42, 'media_type': 'movie', 'watchlisted': true},
        ],
      });
      await Future.wait([UserLibrary.load(), UserLibrary.load()]);
      await UserLibrary.load();
      expect(adapter.count('/track/library/a'), 1);
      expect(UserLibrary.isInWatchlist(42, MediaType.movie), isTrue);
      await LibraryApi.upsert(
        tmdbId: 42,
        mediaType: MediaType.movie,
        watchlisted: false,
      );
      adapter.respond = (_) => jsonBody({'result': []});
      await UserLibrary.load();
      expect(
        adapter.requests
            .where(
              (r) => r.method == 'GET' && r.path.contains('/track/library/a'),
            )
            .length,
        2,
      );
      expect(UserLibrary.watchlist.value, isEmpty);

      final old = Completer<ResponseBody>();
      adapter.respond = (request) => request.path.endsWith('/a')
          ? old.future
          : jsonBody({
              'result': [
                {'tmdb_id': 20, 'media_type': 'movie', 'watchlisted': true},
              ],
            });
      final stale = UserLibrary.load(force: true);
      BackendApi.authState.setProfile(profile('b'));
      await UserLibrary.load();
      old.complete(
        jsonBody({
          'result': [
            {'tmdb_id': 99, 'media_type': 'movie', 'watchlisted': true},
          ],
        }),
      );
      await stale;
      expect(UserLibrary.watchlist.value, {'movie:20'});
      BackendApi.authState.setLoggedIn(null);
      await UserLibrary.load();
      expect(UserLibrary.watchlist.value, isEmpty);
    },
  );
}
