import 'dart:async';
import 'dart:convert';
import 'package:petal/api/cache/versioned_dataset.dart';

Future<void> main() async {
  final disk = <String, String>{};
  var scope = 'account:profile';
  var clock = DateTime.utc(2026, 11, 3);
  var stamp = <String, dynamic>{'generation': 'g1', 'progress_version': 1};
  var loads = 0;
  var checks = 0;
  var remote = <int>[1, 2];
  Future<Map<String, dynamic>?> Function()? checkOverride;
  Future<void> Function(String, String)? writeOverride;
  VersionedDataset<List<int>> dataset({Duration? age, String server = 'https://server'}) =>
      VersionedDataset<List<int>>(
        name: 'history', versionField: 'progress_version', maxAge: age,
        encode: (v) => v, decode: (v) => (v as List).cast<int>(),
        server: () => server, isCurrentScope: (s) => s == scope,
        versions: (_, _) async { checks++; return checkOverride == null ? stamp : await checkOverride!(); },
        invalidateVersions: (_) {},
        read: (key) async => disk[key],
        write: (key, value) async {
          if (writeOverride != null) await writeOverride!(key, value);
          disk[key] = value;
        },
        remove: (key) async { disk.remove(key); },
        now: () => clock,
      );
  Future<List<int>> load() async { loads++; return [...remote]; }
  Future<List<int>> get(VersionedDataset<List<int>> d, {bool force = true,
      void Function(List<int>)? updated}) => d.get(
        scope: scope, profileId: 'profile', load: load, force: force,
        onUpdated: updated ?? (_) {},
      );
  var d = dataset();
  assert((await get(d)).join(',') == '1,2');
  assert(loads == 1 && disk.length == 1);
  await get(d);
  assert(loads == 1 && checks == 2);
  print('PASS matching versions skip dataset downloads');

  final gate = Completer<Map<String, dynamic>?>();
  checkOverride = () => gate.future;
  d = dataset();
  var restored = false;
  final visible = get(d, force: false).then((v) { restored = v.length == 2; return v; });
  await Future<void>.delayed(Duration.zero);
  assert(restored && !gate.isCompleted);
  stamp = {'generation': 'g1', 'progress_version': 2};
  remote = [];
  gate.complete(stamp);
  await visible;
  await get(d);
  assert((await get(d)).isEmpty && loads == 2);
  assert((jsonDecode(disk.values.single)['data'] as List).isEmpty);
  checkOverride = null;
  print('PASS restart renders saved data before checking; deletions replace the snapshot');

  stamp = {'generation': 'g2', 'progress_version': 2};
  remote = [3];
  await get(d);
  assert(loads == 3 && (await get(d)).single == 3);
  print('PASS generation changes rebuild snapshots even with equal versions');

  d = dataset(age: const Duration(minutes: 5));
  await get(d);
  final previousLoads = loads;
  clock = clock.add(const Duration(minutes: 6));
  await get(d);
  assert(loads == previousLoads + 1);
  print('PASS timed data refreshes with unchanged versions');

  scope = 'account:other-profile';
  final other = dataset();
  remote = [9];
  await get(other);
  assert(disk.length == 2);
  scope = 'account:profile';
  assert((await get(dataset())).single == 3);
  final otherServer = dataset(server: 'https://other-server');
  remote = [11];
  await get(otherServer);
  assert(disk.length == 3);
  print('PASS snapshots are isolated by account/profile and server');

  final waiting = Completer<List<int>>();
  final raced = dataset();
  raced.invalidate(scope);
  stamp = {'generation': 'g2', 'progress_version': 3};
  var publishedOld = false;
  final old = raced.get(scope: scope, profileId: 'profile',
      load: () => waiting.future, onUpdated: (_) => publishedOld = true, force: true);
  final oldFailed = old.then((_) => false, onError: (Object _) => true);
  // Invalidate after the old request starts and before its data returns.
  await Future<void>.delayed(Duration.zero);
  raced.invalidate(scope);
  stamp = {'generation': 'g2', 'progress_version': 4};
  remote = [4];
  await get(raced);
  waiting.complete([99]);
  assert(await oldFailed);
  assert(!publishedOld && (await get(raced)).single == 4);
  print('PASS local writes prevent an old response from replacing newer data');

  checkOverride = () async => null;
  final legacy = dataset(server: 'https://legacy');
  remote = [5];
  assert((await get(legacy)).single == 5);
  print('PASS older backends fall back to normal reads');

  checkOverride = null;
  writeOverride = (_, _) async => throw StateError('disk full');
  final fullDisk = dataset(server: 'https://full-disk');
  remote = [6];
  assert((await get(fullDisk)).single == 6);
  print('PASS disk failures do not hide fetched data');
  print('All persistent cache checks passed');
}
