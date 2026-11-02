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
      GoRoute(
        path: '/history',
        builder: (context, state) => const WatchHistoryPage(),
      ),
      ShellRoute(
        navigatorKey: PetalApp.shellNavigatorKey,
        builder: (context, state, child) =>
            AppNavigation(state: state, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final q = state.uri.queryParameters['q'] ?? '';
          return SearchResultsPage(query: q);
        },
      ),
      GoRoute(
        path: '/series',
        builder: (context, state) {
          final tmdbId = state.uri.queryParameters['tmdb'];
          final imdbId = state.uri.queryParameters['imdb'];
          return ShowOverviewPage(
            tmdbId: tmdbId != null ? int.tryParse(tmdbId) : null,
            imdbId: imdbId,
          );
        },
      ),
      GoRoute(
        path: '/episode',
        builder: (context, state) {
          final tmdb =
              int.tryParse(state.uri.queryParameters['tmdb'] ?? '') ?? 0;
          final season =
              int.tryParse(state.uri.queryParameters['s'] ?? '') ?? 1;
          final episode =
              int.tryParse(state.uri.queryParameters['e'] ?? '') ?? 1;
          return EpisodeDetailPage(
            tmdbId: tmdb,
            season: season,
            episode: episode,
          );
        },
      ),
      GoRoute(
        path: '/movie',
        builder: (context, state) {
          final imdbId = state.uri.queryParameters['imdb'];
          final tmdbId = state.uri.queryParameters['tmdb'];
          return MovieOverviewPage(
            tmdbId: tmdbId != null ? int.tryParse(tmdbId) : null,
            imdbId: imdbId,
          );
        },
      ),
      GoRoute(
        path: '/collection',
        builder: (context, state) => CollectionPage(),
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
        path: '/downloads',
        builder: (context, state) => const DownloadsPage(),
      ),
      GoRoute(path: '/settings', builder: (context, state) => SettingsPage()),
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
        builder: (_, _) => const HomeCustomizationPage(),
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
