import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/main.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/models/stream.dart';
import 'package:petal/navigation/navigation.dart';
import 'package:petal/pages/actor_overview.dart';
import 'package:petal/pages/addons.dart';
import 'package:petal/pages/collection.dart';
import 'package:petal/pages/comments_page.dart';
import 'package:petal/pages/dashboard/search_results_page.dart';
import 'package:petal/pages/episode_detail.dart';
import 'package:petal/pages/episode_overview.dart';
import 'package:petal/pages/login.dart';
import 'package:petal/pages/licenses.dart';
import 'package:petal/pages/movie_overview.dart';
import 'package:petal/pages/offline.dart';
import 'package:petal/pages/player/player_screen.dart';
import 'package:petal/pages/public_profile_page.dart';
import 'package:petal/pages/settings.dart';
import 'package:petal/pages/stats_page.dart';
import 'package:petal/pages/streams.dart';
import 'package:petal/pages/trakt_import_page.dart';
import 'package:petal/widgets/catalog/catalog_widget.dart';
import 'package:go_router/go_router.dart';

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
        builder: (context, state, child) => Navigation(state: state, child: child),
        routes: [GoRoute(path: '/', builder: (context, state) => const CatalogWidget())],
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

          return EpisodeOverview(tmdbId: tmdbId != null ? int.tryParse(tmdbId) : null, imdbId: imdbId);
        },
      ),
      GoRoute(
        path: '/episode',
        builder: (context, state) {
          final tmdb = int.tryParse(state.uri.queryParameters['tmdb'] ?? '') ?? 0;
          final season = int.tryParse(state.uri.queryParameters['s'] ?? '') ?? 1;
          final episode = int.tryParse(state.uri.queryParameters['e'] ?? '') ?? 1;
          return EpisodeDetailPage(tmdbId: tmdb, season: season, episode: episode);
        },
      ),
      GoRoute(
        path: '/movie',
        builder: (context, state) {
          final imdbId = state.uri.queryParameters['imdb'];
          final tmdbId = state.uri.queryParameters['tmdb'];

          return MovieOverview(tmdbId: tmdbId != null ? int.tryParse(tmdbId) : null, imdbId: imdbId);
        },
      ),
      GoRoute(path: '/collection', builder: (context, state) => Collection()),
      GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) => PublicProfilePage(profileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/comments',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'show';
          final tmdb = int.tryParse(state.uri.queryParameters['tmdb'] ?? '') ?? 0;
          final title = state.uri.queryParameters['title'] ?? 'Comments';
          return CommentsPage(mediaType: type, tmdbId: tmdb, title: title);
        },
      ),
      GoRoute(
        path: '/person/:id',
        builder: (context, state) => ActorOverview(personId: int.parse(state.pathParameters['id']!)),
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

      GoRoute(path: '/settings', builder: (context, state) => Settings()),
      GoRoute(path: '/trakt-import', builder: (context, state) => const TraktImportPage()),
      GoRoute(
        path: '/licenses',
        builder: (context, state) => OpenSourceLicenses(
          applicationName: state.uri.queryParameters['name'] ?? 'Petal',
          applicationVersion: state.uri.queryParameters['version'] ?? '',
        ),
      ),
      GoRoute(path: '/addons', builder: (context, state) => Addons()),
      GoRoute(path: '/offline', builder: (context, state) => Offline()),
      GoRoute(path: '/login', builder: (context, state) => Login()),
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
            episode: (season != null && episode != null) ? Episode(seasonNumber: int.parse(season), episodeNumber: int.parse(episode)) : null,
            progress: progress != null ? double.parse(progress) : null,
            stream: streamItem,
          );
        },
      ),
    ],
  );
}
