import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/widgets/downloads/download_tile.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

void main() {
  testWidgets('shared Home card badge follows progress regardless of shelf', (
    tester,
  ) async {
    WatchHistoryItem history(List<double> progress) =>
        WatchHistoryItem.fromJson({
          'tmdb_id': 42,
          'media_type': 'show',
          'updated_at': 1700000000,
          'episodes': [
            for (var i = 0; i < progress.length; i++)
              {'season': 1, 'episode': i + 1, 'completion': progress[i]},
          ],
        });
    BackendCache.continueWatching.value = [];
    BackendCache.watchHistory.value = [
      history([0.3]),
    ];
    Widget card(String shelf) => ShadcnApp(
      home: Scaffold(
        child: SizedBox(
          width: 320,
          height: 180,
          child: MediaCard(
            label: shelf,
            showLogo: false,
            image: const ColoredBox(color: Colors.pink),
            target: const MediaCardTarget(
              tmdbId: 42,
              type: MediaType.show,
              totalEpisodes: 2,
            ),
          ),
        ),
      ),
    );
    for (final shelf in ['Liked', 'Stalled', 'Most Watched']) {
      await tester.pumpWidget(card(shelf));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.circlePlay), findsOneWidget);
    }
    BackendCache.watchHistory.value = [
      history([1, 1]),
    ];
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.circlePlay), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'download shows saved names and creates an offline playback request',
    (tester) async {
      final entry = DownloadEntry(
        id: 'show-42-1-2',
        title: 'source filename',
        tmdbId: 42,
        season: 1,
        episode: 2,
        mediaTitle: 'Example Show',
        episodeTitle: 'The second episode',
        status: DownloadStatus.done,
        path: '/tmp/my downloaded episode.mp4',
        playbackProgress: 0.4,
      );
      StreamItem? opened;
      Uri? openedUri;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(child: DownloadTile(entry: entry)),
          ),
          GoRoute(
            path: '/player',
            builder: (_, state) {
              opened = state.extra as StreamItem;
              openedUri = state.uri;
              return const Scaffold(child: Text('Local playback'));
            },
          ),
          GoRoute(
            path: '/series',
            builder: (_, _) => const Scaffold(child: Text('Show details')),
          ),
        ],
      );
      await tester.pumpWidget(ShadcnApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Example Show'), findsOneWidget);
      expect(find.text('S01E02 · The second episode'), findsOneWidget);
      final menu = tester.widget<ContextMenu>(find.byType(ContextMenu));
      final labels = menu.items.whereType<MenuButton>().map(
        (button) => (button.child as Text).data,
      );
      expect(
        labels,
        containsAll(['Play download', 'View show', 'Delete download']),
      );
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(opened!.isLocal, isTrue);
      expect(opened!.download, entry);
      expect(Uri.parse(opened!.url).toFilePath(), entry.path);
      expect(openedUri!.queryParameters['p'], '0.4');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
}
