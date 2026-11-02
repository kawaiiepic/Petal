import 'package:petal/widgets/media/media_artwork_placeholder.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/widgets/media/rating_indicator.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/media/in_progress_indicator.dart';
import 'package:petal/widgets/media/media_title_logo.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Shared artwork, title logos, and library menus. Shelves only add extra actions.
class MediaCard extends StatefulWidget {
  final String? imageUrl;
  final Widget? image;
  final String? label;
  final Widget? overlay;
  final VoidCallback? onTap;
  final MediaCardTarget? target;
  final List<MenuItem> extraContextItems;
  final bool showDefaultContextMenu;
  final String primaryActionLabel;
  final Orientation orientation;
  final bool isLoading;
  final bool showLogo;
  final String? logoUrl;

  const MediaCard({
    super.key,
    this.imageUrl,
    this.image,
    this.label,
    this.overlay,
    this.onTap,
    this.target,
    this.extraContextItems = const [],
    this.showDefaultContextMenu = true,
    this.primaryActionLabel = 'Play',
    this.orientation = Orientation.portrait,
    this.showLogo = true,
    this.isLoading = false,
    this.logoUrl,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  Future<int?>? _idFuture;
  Future<String?>? _logo;
  int? _resolvedId;
  int _generation = 0;
  int? _totalEpisodes;
  Future<void>? _countFuture;

  @override
  void initState() {
    super.initState();
    _load();
    BackendCache.watchHistory.addListener(_resolveProgressTarget);
    BackendCache.continueWatching.addListener(_resolveProgressTarget);
  }

  @override
  void didUpdateWidget(MediaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target?.tmdbId != widget.target?.tmdbId ||
        oldWidget.target?.imdbId != widget.target?.imdbId ||
        oldWidget.target?.type != widget.target?.type ||
        oldWidget.orientation != widget.orientation ||
        oldWidget.showLogo != widget.showLogo ||
        oldWidget.logoUrl != widget.logoUrl ||
        oldWidget.isLoading != widget.isLoading ||
        oldWidget.target?.totalEpisodes != widget.target?.totalEpisodes)
      _load();
  }

  void _load() {
    _generation++;
    _idFuture = null;
    _countFuture = null;
    _totalEpisodes = widget.target?.totalEpisodes;
    _resolvedId = widget.target?.tmdbId;
    _logo = null;
    if (widget.isLoading) return;
    _resolveProgressTarget();
    if (!widget.showLogo || widget.orientation != Orientation.landscape) return;
    if (widget.logoUrl != null) {
      _logo = Future.value(widget.logoUrl);
    } else if (widget.target != null) {
      final type = widget.target!.type;
      _logo = _resolveId().then(
        (id) => id == null ? null : TMDB.titleLogo(id, type),
      );
    }
  }

  void _resolveProgressTarget() {
    final target = widget.target;
    if (widget.isLoading || target == null) return;
    if (BackendCache.watchHistory.value.isEmpty &&
        BackendCache.continueWatching.value.isEmpty)
      return;
    if (_resolvedId == null) {
      if (_idFuture == null) _resolveId().catchError((Object _) => null);
      return;
    }
    if (target.type != MediaType.show ||
        _totalEpisodes != null ||
        _countFuture != null)
      return;
    if (!BackendCache.watchHistory.value.any(
      (item) =>
          item.tmdbId == _resolvedId &&
          item.mediaType == target.type &&
          item.episodes.any(
            (episode) => WatchProgress.isWatched(episode.completion),
          ),
    ))
      return;
    final generation = _generation;
    _countFuture = () async {
      try {
        final show = await TMDB.tvShow(_resolvedId!);
        if (mounted && generation == _generation)
          setState(() => _totalEpisodes = show.numberOfEpisodes);
      } catch (_) {
        /* Keep an unknown total unmarked when metadata is unavailable. */
      }
    }();
  }

  @override
  void dispose() {
    BackendCache.watchHistory.removeListener(_resolveProgressTarget);
    BackendCache.continueWatching.removeListener(_resolveProgressTarget);
    super.dispose();
  }

  Future<int?> _resolveId() {
    final target = widget.target;
    if (target == null) return Future.value(null);
    if (target.tmdbId != null) return Future.value(target.tmdbId);
    final generation = _generation;
    return _idFuture ??= () async {
      try {
        final result = await ApiCache.getTmdbSearch(target.imdbId!);
        final matches = target.type == MediaType.movie
            ? result.movies
            : result.tv;
        final id = matches.firstOrNull?.id;
        if (mounted && generation == _generation) {
          setState(() => _resolvedId = id);
          _resolveProgressTarget();
        }
        return id;
      } catch (_) {
        if (generation == _generation) _idFuture = null;
        rethrow;
      }
    }();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted)
        AppNotifications.sendNotification(
          const Text('Could not update title'),
          const Text('Please try again.'),
        );
    }
  }

  String get _infoRoute {
    final target = widget.target!;
    final id = _resolvedId;
    return '/${target.type == MediaType.movie ? 'movie' : 'series'}?${id == null ? 'imdb=${Uri.encodeQueryComponent(target.imdbId!)}' : 'tmdb=$id'}';
  }

  void _open() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    final target = widget.target;
    if (target == null) return;
    if (_resolvedId != null &&
        (target.type == MediaType.movie || target.isEpisode)) {
      final route = target.type == MediaType.movie
          ? '/streams?movie=$_resolvedId'
          : '/streams?show=$_resolvedId&s=${target.season}&e=${target.episode}';
      context.push(route);
    } else {
      context.push(_infoRoute);
    }
  }

  Future<void> _sources() async {
    final id = await _resolveId();
    if (!mounted || id == null) return;
    final target = widget.target!;
    context.push(
      target.type == MediaType.movie
          ? '/streams?movie=$id'
          : target.isEpisode
          ? '/streams?show=$id&s=${target.season}&e=${target.episode}'
          : _infoRoute,
    );
  }

  bool get _watched {
    final target = widget.target!;
    final id = _resolvedId;
    if (id == null) return false;
    if (!target.isEpisode) return UserLibrary.isWatched(id, target.type);
    return BackendCache.watchHistory.value
        .where((item) => item.tmdbId == id && item.mediaType == target.type)
        .any(
          (item) => item.episodes.any(
            (episode) =>
                episode.season == target.season &&
                episode.episode == target.episode &&
                WatchProgress.isWatched(episode.completion),
          ),
        );
  }

  Future<void> _libraryAction(Future<void> Function(int id) action) async {
    final profile = BackendApi.profileCacheKey;
    final id = await _resolveId();
    if (id == null || profile == null || profile != BackendApi.profileCacheKey)
      return;
    await action(id);
  }

  Future<void> _toggleWatched(int id) async {
    final profile = BackendApi.profileCacheKey;
    await BackendCache.fetchWatchHistory();
    if (profile != BackendApi.profileCacheKey) return;
    final target = widget.target!;
    if (target.isEpisode) {
      await BackendApi.setProgress(
        id,
        target.type,
        _watched ? 0 : 1,
        season: target.season,
        episode: target.episode,
      );
      await Future.wait([
        BackendCache.fetchWatchHistory(force: true),
        BackendCache.fetchContinueWatching(),
      ]);
    } else {
      await UserLibrary.toggleWatched(id, target.type);
    }
  }

  List<MenuItem> _contextItems() {
    final target = widget.target;
    final defaults = <MenuItem>[];
    if (widget.showDefaultContextMenu) {
      if (widget.onTap != null || target != null)
        defaults.add(
          MenuButton(
            leading: const Icon(LucideIcons.play),
            child: Text(widget.primaryActionLabel),
            onPressed: (_) => _open(),
          ),
        );
      if (target != null) {
        final inWatchlist =
            _resolvedId != null &&
            UserLibrary.isInWatchlist(_resolvedId!, target.type);
        defaults.addAll([
          MenuButton(
            leading: const Icon(LucideIcons.server),
            child: const Text('Select Source'),
            onPressed: (_) => _run(_sources),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.info),
            child: const Text('More Info'),
            onPressed: (_) => context.push(_infoRoute),
          ),
          const MenuDivider(),
          MenuButton(
            leading: const Icon(LucideIcons.bookmark),
            child: Text(
              inWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
            ),
            onPressed: (_) => _run(
              () => _libraryAction(
                (id) => UserLibrary.toggleWatchlist(
                  id,
                  target.type,
                  name: widget.label,
                ),
              ),
            ),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.check),
            child: Text(_watched ? 'Mark as Unwatched' : 'Mark as Watched'),
            onPressed: (_) => _run(() => _libraryAction(_toggleWatched)),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.thumbsUp),
            child: const Text('Rate'),
            onPressed: (_) => _run(
              () => _libraryAction(
                (id) => UserLibrary.cycleRating(id, target.type),
              ),
            ),
          ),
        ]);
      }
    }
    return [
      ...defaults,
      if (defaults.isNotEmpty && widget.extraContextItems.isNotEmpty)
        const MenuDivider(),
      ...widget.extraContextItems,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        UserLibrary.watchlist,
        UserLibrary.ratings,
        BackendCache.watchHistory,
      ]),
      builder: (context, _) => Semantics(
        label: widget.label,
        button:
            !widget.isLoading &&
            (widget.onTap != null || widget.target != null),
        child: HoverableItem(
          orientation: widget.orientation,
          onTap:
              !widget.isLoading &&
                  (widget.onTap != null || widget.target != null)
              ? _open
              : null,
          contextItems: widget.isLoading ? const [] : _contextItems(),
          extraWidget: widget.isLoading
              ? null
              : Stack(
                  children: [
                    if (_logo != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: IgnorePointer(
                          child: SizedBox(
                            height: 36,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 140,
                                ),
                                child: FutureBuilder<String?>(
                                  future: _logo,
                                  builder: (context, snapshot) =>
                                      snapshot.hasData
                                      ? MediaTitleLogo(url: snapshot.data!)
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.overlay != null) widget.overlay!,
                    if (_resolvedId != null && widget.target != null)
                      Positioned(
                        top: 48,
                        right: 12,
                        child: RatingIndicator(
                          tmdbId: _resolvedId!,
                          type: widget.target!.type,
                        ),
                      ),
                    if (_resolvedId != null && widget.target != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: InProgressIndicator(
                          target: MediaCardTarget(
                            tmdbId: _resolvedId,
                            type: widget.target!.type,
                            totalEpisodes: _totalEpisodes,
                          ),
                        ),
                      ),
                  ],
                ),
          image: widget.isLoading
              ? const MediaArtworkPlaceholder(loading: true)
              : widget.image ??
                    MediaArtwork(imageUrl: widget.imageUrl, cacheWidth: 780),
        ),
      ),
    );
  }
}
