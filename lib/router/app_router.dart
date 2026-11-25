import 'package:petal/router/popup_page.dart';
import 'package:petal/router/episode_sheet_page.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart'
    show Page, ShadcnPage, Widget;
import 'package:petal/pages/watch_history_page.dart';
import 'package:petal/pages/home_customization_page.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/navigation/app_navigation.dart';
import 'package:petal/pages/actor_overview_page.dart';
import 'package:petal/pages/addons_page.dart';
import 'package:petal/pages/collection_page.dart';
import 'package:petal/pages/comments_page.dart';
import 'package:petal/pages/dashboard/search_results_page.dart';
import 'package:petal/pages/downloads_page.dart';
import 'package:petal/pages/episode_detail_page.dart';
import 'package:petal/pages/home_page.dart';
import 'package:petal/pages/login_page.dart';
import 'package:petal/pages/movie_overview_page.dart';
import 'package:petal/pages/offline_page.dart';
import 'package:petal/pages/open_source_licenses_page.dart';
import 'package:petal/pages/player/stream_player.dart';
import 'package:petal/pages/public_profile_page.dart';
import 'package:petal/pages/settings_page.dart';
import 'package:petal/pages/show_overview_page.dart';
import 'package:petal/pages/stats_page.dart';
import 'package:petal/pages/streams_page.dart';
import 'package:petal/pages/trakt_import_page.dart';

Page<void> _navigationPage(GoRouterState state, Widget child) =>
    ShadcnPage<void>(key: state.pageKey, child: child);

List<GoRoute> _libraryRoutes() => [
  GoRoute(
    path: '/collection',
    pageBuilder: (context, state) => _navigationPage(state, CollectionPage()),
  ),
  GoRoute(
    path: '/history',
    pageBuilder: (context, state) =>
        _navigationPage(state, const WatchHistoryPage()),
  ),
  GoRoute(
    path: '/downloads',
    pageBuilder: (context, state) =>
        _navigationPage(state, const DownloadsPage()),
  ),
];

GoRoute _searchRoute() => GoRoute(
  path: '/search',
  pageBuilder: (context, state) => _navigationPage(
    state,
    SearchResultsPage(query: state.uri.queryParameters['q'] ?? ''),
  ),
);

class AppRouter {
  static final appRouter = GoRouter(
    navigatorKey: PetalApp.rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: BackendApi.authState,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final onOffline = state.matchedLocation == '/offline';

      if (BackendApi.authState.initializing) {
        return onOffline ? null : '/offline';
      }

      if (!BackendApi.authState.loggedIn && !loggingIn) return '/login';

      if (BackendApi.authState.loggedIn && onOffline) return '/';

      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: PetalApp.shellNavigatorKey,
        builder: (context, state, child) =>
            AppNavigation(state: state, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ..._libraryRoutes(),
          _searchRoute(),
        ],
      ),
      GoRoute(
        path: '/series',
        pageBuilder: (context, state) {
          final tmdbId = state.uri.queryParameters['tmdb'];
          final imdbId = state.uri.queryParameters['imdb'];
          return _navigationPage(
            state,
            ShowOverviewPage(
              tmdbId: tmdbId != null ? int.tryParse(tmdbId) : null,
              imdbId: imdbId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/episode',
        pageBuilder: (context, state) {
          final tmdb =
              int.tryParse(state.uri.queryParameters['tmdb'] ?? '') ?? 0;
          final season =
              int.tryParse(state.uri.queryParameters['s'] ?? '') ?? 1;
          final episode =
              int.tryParse(state.uri.queryParameters['e'] ?? '') ?? 1;
          return EpisodeSheetPage(
            key: state.pageKey,
            builder: (controller) => EpisodeDetailPage(
              tmdbId: tmdb,
              season: season,
              episode: episode,
              popup: true,
              scrollController: controller,
            ),
          );
        },
      ),
      GoRoute(
        path: '/movie',
        pageBuilder: (context, state) {
          final imdbId = state.uri.queryParameters['imdb'];
          final tmdbId = state.uri.queryParameters['tmdb'];
          return _navigationPage(
            state,
            MovieOverviewPage(
              tmdbId: tmdbId != null ? int.tryParse(tmdbId) : null,
              imdbId: imdbId,
            ),
          );
        },
      ),
      GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) =>
            PublicProfilePage(profileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/comments',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'show';
          final tmdb =
              int.tryParse(state.uri.queryParameters['tmdb'] ?? '') ?? 0;
          final title = state.uri.queryParameters['title'] ?? 'Comments';
          return CommentsPage(mediaType: type, tmdbId: tmdb, title: title);
        },
      ),
      GoRoute(
        path: '/person/:id',
        builder: (context, state) =>
            ActorOverviewPage(personId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        parentNavigatorKey: PetalApp.rootNavigatorKey,
        path: '/streams',
        builder: (context, state) {
          final showId = state.uri.queryParameters['show'];
          final season = state.uri.queryParameters['s'];
          final episode = state.uri.queryParameters['e'];
          final movieId = state.uri.queryParameters['movie'];
          final download = state.uri.queryParameters['download'] == '1';
          return StreamsPage(
            showId: showId != null ? int.parse(showId) : null,
            episode: (season != null && episode != null)
                ? Episode(
                    seasonNumber: int.parse(season),
                    episodeNumber: int.parse(episode),
                  )
                : null,
            movieId: movieId != null ? int.parse(movieId) : null,
            download: download,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _navigationPage(state, SettingsPage()),
      ),
      GoRoute(
        path: '/trakt-import',
        builder: (context, state) => const TraktImportPage(),
      ),
      GoRoute(
        path: '/licenses',
        builder: (context, state) => OpenSourceLicensesPage(
          applicationName: state.uri.queryParameters['name'] ?? 'Petal',
          applicationVersion: state.uri.queryParameters['version'] ?? '',
        ),
      ),
      GoRoute(
        path: '/home-layout',
        pageBuilder: (context, state) => PopupPage(
          key: state.pageKey,
          title: 'Customize Home',
          maxWidth: 620,
          child: const HomeCustomizationPage(popup: true),
        ),
      ),
      GoRoute(path: '/addons', builder: (context, state) => AddonsPage()),
      GoRoute(path: '/offline', builder: (context, state) => OfflinePage()),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(
        parentNavigatorKey: PetalApp.rootNavigatorKey,
        path: '/player',
        builder: (context, state) {
          final mediaId = state.uri.queryParameters['media'];
          final season = state.uri.queryParameters['s'];
          final episode = state.uri.queryParameters['e'];
          final progress = state.uri.queryParameters['p'];
          final streamItem = state.extra as StreamItem?;
          return StreamPlayer(
            mediaId: int.parse(mediaId!),
            episode: (season != null && episode != null)
                ? Episode(
                    seasonNumber: int.parse(season),
                    episodeNumber: int.parse(episode),
                  )
                : null,
            progress: progress != null ? double.parse(progress) : null,
            stream: streamItem,
          );
        },
      ),
    ],
  );
}
