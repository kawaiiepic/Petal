import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/widgets/downloads/download_storage_card.dart';
import 'package:petal/widgets/downloads/download_tile.dart';
import 'package:petal/widgets/ios/ios_context_menu.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_progress_bar.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class _UnavailableStoragePath extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => null;
}

void main() {
  testWidgets(
    'storage card stops calculating when the storage path is unavailable',
    (tester) async {
      final originalPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _UnavailableStoragePath();
      addTearDown(() => PathProviderPlatform.instance = originalPaths);
      await tester.pumpWidget(
        const ShadcnApp(home: Scaffold(child: DownloadStorageCard())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Download size unavailable'), findsOneWidget);
      expect(find.text('Calculating download size…'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'shared Home cards keep their progress bar without a watched badge',
    (tester) async {
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
                season: 1,
                episode: 1,
              ),
            ),
          ),
        ),
      );
      for (final shelf in ['Liked', 'Stalled', 'Most Watched']) {
        await tester.pumpWidget(card(shelf));
        await tester.pumpAndSettle();
        expect(find.byType(MediaProgressBar), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Playback progress')),
          findsOneWidget,
        );
        expect(find.byIcon(LucideIcons.circlePlay), findsNothing);
      }
      BackendCache.watchHistory.value = [
        history([1, 1]),
      ];
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Playback progress')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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
      final menu = tester.widget<PetalContextMenu>(
        find.byType(PetalContextMenu),
      );
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
