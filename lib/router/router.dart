import 'package:petal/api/api.dart';
import 'package:petal/api/trakt/trakt_helper.dart';
import 'package:petal/main.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/models/stream.dart';
import 'package:petal/navigation/navigation.dart';
import 'package:petal/pages/addons.dart';
import 'package:petal/pages/dashboard/search_widget.dart';
import 'package:petal/pages/episode_overview.dart';
import 'package:petal/pages/login.dart';
import 'package:petal/pages/movie_overview.dart';
import 'package:petal/pages/offline.dart';
import 'package:petal/pages/player/player_old.dart';
import 'package:petal/pages/settings.dart';
import 'package:petal/pages/streams.dart';
import 'package:petal/pages/trakt/traktlogin.dart';
import 'package:petal/router/dialog_page.dart';
import 'package:petal/router/routes/catalog_widget.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final settingsRoute = GoRoute(
    path: '/settings',
    pageBuilder: (context, state) => DialogPage(builder: (context) => Settings()),
  );
  static final appRouter = GoRouter(
    navigatorKey: PetalApp.rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: TraktApi.authState,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (!Api.healthy.value) return '/offline';

      if (!TraktApi.authState.loggedIn) return '/login';
      if (TraktApi.authState.loggedIn && loggingIn) return '/';

      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: PetalApp.shellNavigatorKey,
        builder: (context, state, child) => Navigation(child: child),
        routes: [
          GoRoute(path: '/', routes: [settingsRoute], builder: (context, state) => const CatalogWidget()),
        ],
      ),

      GoRoute(
        path: '/series/:id',
        builder: (context, state) => EpisodeOverview(tmdbId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) => MovieOverview(tmdbId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        parentNavigatorKey: PetalApp.rootNavigatorKey,
        path: '/streams',
        builder: (context, state) {
          final showId = state.uri.queryParameters['show'];
          final season = state.uri.queryParameters['s'];
          final episode = state.uri.queryParameters['e'];
          final movieId = state.uri.queryParameters['movie'];

          return StreamsPage(
            showId: showId != null ? int.parse(showId) : null,
            episode: (season != null && episode != null) ? Episode(seasonNumber: int.parse(season), episodeNumber: int.parse(episode)) : null,
            movieId: movieId != null ? int.parse(movieId) : null,
          );
        },
      ),

      settingsRoute,
      GoRoute(
        path: '/addons',
        pageBuilder: (context, state) => DialogPage(builder: (context) => Addons()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => DialogPage(builder: (context) => Search()),
      ),
      GoRoute(path: '/offline', builder: (context, state) => Offline()),
      GoRoute(path: '/login', builder: (context, state) => Login()),
      GoRoute(path: '/traktLogin', builder: (context, state) => TraktLoginPage()),
      GoRoute(
        parentNavigatorKey: PetalApp.rootNavigatorKey,
        path: '/player',
        builder: (context, state) {
          final showId = state.uri.queryParameters['show'];
          final season = state.uri.queryParameters['s'];
          final episode = state.uri.queryParameters['e'];
          final movieId = state.uri.queryParameters['movie'];
          final streamItem = state.extra as StreamItem?;

          return StreamPlayer(
            showId: showId != null ? int.parse(showId) : null,
            episode: (season != null && episode != null) ? Episode(seasonNumber: int.parse(season), episodeNumber: int.parse(episode)) : null,
            movieId: movieId != null ? int.parse(movieId) : null,
            stream: streamItem,
          );
        },
      ),
    ],
  );
}
