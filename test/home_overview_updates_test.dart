import 'package:sizer/sizer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/profile.dart';
import 'package:petal/pages/episode_detail_page.dart';
import 'package:petal/widgets/media/rating_indicator.dart';
import 'package:petal/widgets/overview/overview_hero_actions.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

import 'support/recording_adapter.dart';

Widget harness(Widget child) => Sizer(
  builder: (context, orientation, screenType) =>
      ShadcnApp(home: Scaffold(child: child)),
);

void main() {
  testWidgets('liked and loved use distinct reactive icons', (tester) async {
    UserLibrary.ratings.value = {'show:42': TitleRating.like};
    await tester.pumpWidget(
      harness(const RatingIndicator(tmdbId: 42, type: MediaType.show)),
    );
    expect(find.byIcon(LucideIcons.thumbsUp), findsOneWidget);
    expect(find.text('Liked'), findsNothing);
    UserLibrary.ratings.value = {'show:42': TitleRating.love};
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.heart), findsOneWidget);
    expect(find.byIcon(LucideIcons.thumbsUp), findsNothing);
    UserLibrary.ratings.value = {};
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.heart), findsNothing);
  });

  testWidgets('next episode and movie labels coexist with watch metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const WatchMetaOverlay(
          episodeLabel: 'S2 · E3',
          durationLabel: '45m',
          remainingLabel: '2 episodes left',
        ),
      ),
    );
    expect(find.text('S2 · E3 · 45m'), findsOneWidget);
    expect(find.text('2 episodes left'), findsOneWidget);
    await tester.pumpWidget(
      harness(const WatchMetaOverlay(episodeLabel: 'Movie')),
    );
    expect(find.text('Movie'), findsOneWidget);
  });

  testWidgets(
    'show hero exposes trailer and shared library controls without comments button',
    (tester) async {
      await tester.pumpWidget(
        harness(
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                OverviewHeroActions(
                  play: const Text('Play'),
                  mediaType: MediaType.show,
                  tmdbId: 42,
                  onTrailer: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.video), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);
      expect(find.byIcon(LucideIcons.thumbsUp), findsOneWidget);
      expect(find.byIcon(LucideIcons.messageCircle), findsNothing);
    },
  );

  testWidgets('episode context menu writes progress for only that episode', (
    tester,
  ) async {
    final adapter = RecordingAdapter();
    BackendApi.dio = Dio()..httpClientAdapter = adapter;
    BackendApi.authState.setLoggedIn({'id': 'user'});
    BackendApi.authState.setProfile(
      Profile(id: 'a', userId: 'user', name: 'a', createdAt: ''),
    );
    BackendCache.watchHistory.value = [];
    TMDB.clearCache();
    adapter.respond = (request) => request.path.contains('/tmdb')
        ? jsonBody({
            'id': 42,
            'name': 'Example',
            'season_number': 2,
            'episode_number': 3,
            'overview': '',
            'guest_stars': [],
          })
        : jsonBody({'result': []});
    await tester.pumpWidget(
      harness(const EpisodeDetailPage(tmdbId: 42, season: 2, episode: 3)),
    );
    await tester.pumpAndSettle();
    final menu = tester.widget<ContextMenu>(find.byType(ContextMenu));
    final button = menu.items.whereType<MenuButton>().single;
    expect((button.child as Text).data, 'Mark as Watched');
    button.onPressed!(tester.element(find.byType(EpisodeDetailPage)));
    await tester.pumpAndSettle();
    final writes = adapter.requests.where(
      (request) => request.method == 'PUT' || request.method == 'POST',
    );
    expect(writes.length, 1);
    final data = writes.single.data as Map;
    expect(data['completion'], 1);
    expect(data['season'], 2);
    expect(data['episode'], 3);
    await tester.pumpWidget(const SizedBox.shrink());
    BackendApi.authState.setLoggedIn(null);
  });
}
