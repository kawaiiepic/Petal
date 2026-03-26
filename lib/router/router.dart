import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/main.dart';
import 'package:blssmpetal/models/custom_model.dart';
import 'package:blssmpetal/navigation/navigation.dart';
import 'package:blssmpetal/pages/addons.dart';
import 'package:blssmpetal/pages/episode_overview.dart';
import 'package:blssmpetal/pages/login.dart';
import 'package:blssmpetal/pages/movie_overview.dart';
import 'package:blssmpetal/pages/player/player_old.dart';
import 'package:blssmpetal/pages/settings.dart';
import 'package:blssmpetal/router/dialog_page.dart';
import 'package:blssmpetal/router/routes/catalog_widget.dart';
import 'package:blssmpetal/pages/dashboard/dashboard.dart';
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

      print(TraktApi.authState.loggedIn);

      if (!TraktApi.authState.loggedIn) return '/login';
      if (TraktApi.authState.loggedIn && loggingIn) return '/';

      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: PetalApp.shellNavigatorKey,
        builder: (context, state, child) => Navigation(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Dashboard()),

          GoRoute(
            path: '/catalogs',
            routes: [
              settingsRoute,
              GoRoute(
                path: '/series/:id',
                pageBuilder: (context, state) => DialogPage(
                  builder: (context) {
                    return EpisodeOverview(tmdbId: int.parse(state.pathParameters['id']!));
                  },
                ),
              ),
              GoRoute(
                path: '/movie/:id',
                pageBuilder: (context, state) => DialogPage(
                  builder: (context) {
                    return MovieOverview(tmdbId: int.parse(state.pathParameters['id']!));
                  },
                ),
              ),
            ],
            builder: (context, state) => const CatalogWidget(),
          ),

          GoRoute(
            path: '/tv/:id',
            pageBuilder: (context, state) => DialogPage(builder: (context) => EpisodeOverview(tmdbId: int.parse(state.pathParameters['id']!))),
          ),
        ],
      ),
      settingsRoute,
      GoRoute(
    path: '/addons',
    pageBuilder: (context, state) => DialogPage(builder: (context) => Addons()),
  ),
      GoRoute(path: '/login', builder: (context, state) => Login()),
      GoRoute(
        parentNavigatorKey: PetalApp.rootNavigatorKey,
        path: '/player',
        builder: (context, state) {
          final showId = state.uri.queryParameters['show'];
          final season = state.uri.queryParameters['s'];
          final episode = state.uri.queryParameters['e'];
          final movieId = state.uri.queryParameters['movie'];

          return StreamPlayer(
            showId: showId != null ? int.parse(showId) : null,
            episode: (season != null && episode != null) ? Episode(seasonNumber: int.parse(season), episodeNumber: int.parse(episode)) : null,
            movieId: movieId != null ? int.parse(movieId) : null,
          );
        },
      ),
    ],
  );
}
