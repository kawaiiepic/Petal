import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/cache/async_cache.dart';

void main() {
  test(
    'shares pending work, caches success, and expires completed results',
    () async {
      var now = DateTime(2026);
      var calls = 0;
      final cache = AsyncCache<String, int>(
        ttl: const Duration(minutes: 1),
        now: () => now,
      );
      final pending = Completer<int>();
      Future<int> load() {
        calls++;
        return pending.future;
      }

      final first = cache.get('title', load);
      now = now.add(const Duration(minutes: 2));
      expect(identical(first, cache.get('title', load)), isTrue);
      pending.complete(42);
      expect(await first, 42);
      expect(await cache.get('title', load), 42);
      expect(calls, 1);
      now = now.add(const Duration(minutes: 2));
      expect(
        await cache.get('title', () async {
          calls++;
          return 43;
        }),
        43,
      );
      expect(calls, 2);
    },
  );

  test(
    'forced reads refresh successes while sharing pending refreshes',
    () async {
      final cache = AsyncCache<String, int>(ttl: const Duration(hours: 6));
      expect(await cache.get('title', () async => 1), 1);
      final pending = Completer<int>();
      final refresh = cache.get('title', () => pending.future, force: true);
      expect(
        identical(refresh, cache.get('title', () async => 99, force: true)),
        isTrue,
      );
      pending.complete(2);
      expect(await refresh, 2);
    },
  );

  test('failed requests are evicted and may be retried immediately', () async {
    final cache = AsyncCache<String, int>(ttl: const Duration(minutes: 1));
    await expectLater(
      cache.get('title', () async => throw StateError('offline')),
      throwsStateError,
    );
    expect(await cache.get('title', () async => 2), 2);
  });

  test('an invalidated old request cannot replace a newer result', () async {
    final cache = AsyncCache<String, int>(ttl: const Duration(minutes: 1));
    final pending = Completer<int>();
    final old = cache.get('title', () => pending.future);
    cache.invalidate('title');
    expect(await cache.get('title', () async => 2), 2);
    pending.complete(1);
    expect(await old, 1);
    expect(await cache.get('title', () async => 3), 2);
  });

  test('capacity evicts the least recently used entry', () async {
    final cache = AsyncCache<String, int>(
      ttl: const Duration(minutes: 1),
      maxEntries: 2,
    );
    await cache.get('a', () async => 1);
    await cache.get('b', () async => 2);
    await cache.get('a', () async => 99);
    await cache.get('c', () async => 3);
    expect(await cache.get('b', () async => 4), 4);
  });

  test('an obsolete failure cannot evict a replacement request', () async {
    final cache = AsyncCache<String, int>(ttl: const Duration(minutes: 1));
    final pending = Completer<int>();
    final old = cache.get('title', () => pending.future);
    final failure = expectLater(old, throwsStateError);
    cache.invalidate('title');
    await cache.get('title', () async => 2);
    pending.completeError(StateError('old failure'));
    await failure;
    expect(await cache.get('title', () async => 3), 2);
  });
}
