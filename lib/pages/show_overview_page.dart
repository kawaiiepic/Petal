import 'package:petal/widgets/ios/ios_context_menu.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/utils/show_playback.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/widgets/connection_error_view.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_season.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:petal/utils/media_formatting.dart';
import 'package:petal/widgets/overview/trailers_shelf.dart';
import 'package:petal/widgets/overview/cast_card.dart';
import 'package:petal/widgets/overview/episode_portrait_card.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:petal/widgets/overview/overview_hero_actions.dart';
import 'package:petal/widgets/overview/title_comments.dart';
import 'package:petal/widgets/overview/season_dropdown.dart';
import 'package:petal/widgets/overview/show_recommendation_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shadcn_flutter_skeletonizer/shadcn_flutter_skeletonizer.dart';

class ShowOverviewPage extends StatefulWidget {
  final int? tmdbId;
  final String? imdbId;

  const ShowOverviewPage({super.key, this.tmdbId, this.imdbId})
    : assert(tmdbId != null || imdbId != null);

  @override
  State<ShowOverviewPage> createState() => _ShowOverviewPageState();
}

class _ShowOverviewPageState extends State<ShowOverviewPage> {
  Future<TmdbShow>? _show;
  Future<TmdbSeason>? _season;

  int? _resolvedTmdbId;
  Object? _loadError;
  TmdbShow? _details;
  bool _playbackReady = false;
  bool _hasAiredEpisode = false;
  bool _rewatch = false;
  bool _startingPlayback = false;
  int _selectedSeasonNumber = 1;
  int _targetRevision = 0;
  int _loadRevision = 0;

  Episode episode = Episode(seasonNumber: 1, episodeNumber: 1);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    BackendCache.watchHistory.addListener(_onProgressChanged);
    BackendCache.continueWatching.addListener(_onProgressChanged);
    initData();
  }

  void _onProgressChanged() {
    final details = _details;
    if (details != null) _updatePlaybackTarget(details);
  }

  Future<void> _updatePlaybackTarget(TmdbShow details) async {
    final revision = ++_targetRevision;
    final profile = BackendApi.profileCacheKey;
    if (mounted) setState(() => _playbackReady = false);
    try {
      final target = await ShowPlayback.resolve(
        show: details,
        history: [...BackendCache.watchHistory.value],
        nextUp: [...BackendCache.continueWatching.value],
        loadSeason: (number) => TMDB.tvSeason(details.id, number),
      );
      if (!mounted || revision != _targetRevision ||
          profile != BackendApi.profileCacheKey) return;
      final next = target.episode;
      final changed = next != null && (episode.seasonNumber != next.seasonNumber ||
          episode.episodeNumber != next.episodeNumber);
      setState(() {
        _hasAiredEpisode = next != null;
        _rewatch = target.rewatch;
        _playbackReady = true;
        if (next != null) episode = next;
        if (_season == null || changed) {
          _selectedSeasonNumber = next?.seasonNumber ??
              details.seasons.where((s) => s.seasonNumber > 0)
                  .firstOrNull?.seasonNumber ?? 1;
          _season = TMDB.tvSeason(details.id, _selectedSeasonNumber);
        }
      });
    } catch (error) {
      if (mounted && revision == _targetRevision &&
          profile == BackendApi.profileCacheKey) {
        setState(() => _loadError = error);
      }
    }
  }

  Future<void> _playShow(TmdbShow show, {bool selectSource = false}) async {
    if (_startingPlayback) return;
    final profile = BackendApi.profileCacheKey;
    final target = episode;
    final restarting = _rewatch;
    setState(() => _startingPlayback = true);
    try {
      if (restarting) await HistoryActions.startTitleRewatch(show.id, MediaType.show);
      if (!mounted || profile != BackendApi.profileCacheKey) return;
      await context.push(selectSource
        ? '/streams?show=${show.id}&s=${target.seasonNumber}&e=${target.episodeNumber}'
        : '/player?media=${show.id}&s=${target.seasonNumber}&e=${target.episodeNumber}');
    } catch (error) {
      if (mounted) AppNotifications.sendNotification(
        const Text('Could not start playback'), Text(HistoryActions.errorMessage(error)));
    } finally {
      if (mounted) setState(() => _startingPlayback = false);
    }
  }

  Future<void> initData() async {
    final revision = ++_loadRevision;
    _targetRevision++;
    _details = null;
    setState(() {
      _loadError = null;
      _playbackReady = false;
      _season = null;
    });
    try {
      int? tmdbId = widget.tmdbId;
      if (tmdbId == null && widget.imdbId != null) {
        final result = await ApiCache.getTmdbSearch(widget.imdbId!);
        if (result.tv.isEmpty) throw StateError('Title not found');
        tmdbId = result.tv.first.id;
      }
      if (tmdbId == null || !mounted || revision != _loadRevision) return;
      final show = TMDB.tvShow(tmdbId);
      setState(() {
        _resolvedTmdbId = tmdbId;
        _show = show;
      });
      final details = await show;
      // Use the scoped caches; temporarily unavailable history keeps its saved values.
      await Future.wait([
        BackendCache.fetchWatchHistory().catchError((Object _) {}),
        BackendCache.fetchContinueWatching().catchError((Object _) {}),
      ]);
      if (!mounted || revision != _loadRevision) return;
      _details = details;
      await _updatePlaybackTarget(details);
    } catch (error) {
      if (mounted && revision == _loadRevision) {
        setState(() => _loadError = error);
      }
    }
  }

  @override
  void dispose() {
    _loadRevision++;
    _targetRevision++;
    BackendCache.watchHistory.removeListener(_onProgressChanged);
    BackendCache.continueWatching.removeListener(_onProgressChanged);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _show,
      builder: (context, snapshot) {
        if (_loadError != null || snapshot.hasError) {
          return ConnectionErrorView(
            error: _loadError ?? snapshot.error,
            onRetry: initData,
          );
        }
        final loading = snapshot.connectionState != ConnectionState.done;
        final show = snapshot.hasData ? snapshot.data! : null;
        final cast = show?.credits?.cast.take(12).toList();
        final recommendations = show?.recommendations?.results
            .take(15)
            .toList();

        return Container(
          color: Theme.of(context).colorScheme.background,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MediaArtwork(
                        imageUrl: show?.backdropUrl,
                        isLoading: loading,
                      ),
                      Positioned(
                        bottom: 100,
                        left: 24,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                            maxHeight: 80,
                          ),
                          child: show?.images?.preferredLogo?.url == null
                              ? Text(show?.name ?? 'Loading title')
                              : MediaArtwork(
                                  imageUrl: show!.images!.preferredLogo!.url,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      OverviewHeroActions(
                        mediaType: MediaType.show,
                        tmdbId: _resolvedTmdbId,
                        show: show,
                        title: show?.name,
                        play: PetalContextMenu(
                          items: [
                            MenuButton(
                              trailing: const MenuShortcut(
                                activator: SingleActivator(
                                  LogicalKeyboardKey.bracketLeft,
                                  control: true,
                                ),
                              ),
                              onPressed: (_) {
                                if (show != null && _playbackReady && _hasAiredEpisode) {
                                  _playShow(show, selectSource: true);
                                }
                              },
                              child: const Text('Select Source'),
                            ),
                          ],
                          child: Skeleton.keep(
                            child: Button(
                              onPressed: show != null && _playbackReady && _hasAiredEpisode && !_startingPlayback
                                  ? () => _playShow(show)
                                  : null,
                              style: const ButtonStyle.primary()
                                  .withBorderRadius(
                                    borderRadius: BorderRadius.circular(16),
                                    hoverBorderRadius: BorderRadius.circular(
                                      16,
                                    ),
                                  ),
                              child: Row(
                                spacing: 8,
                                children: [
                                  Icon(LucideIcons.play),
                                  Text(
                                    style: TextStyle(
                                      fontSize: AppTypography.bodySize,
                                    ),
                                    !_playbackReady ? 'Finding next episode…'
                                        : !_hasAiredEpisode ? 'No aired episodes'
                                        : '${_rewatch ? 'Rewatch ' : ''}S${episode.seasonNumber}:E${episode.episodeNumber}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Text(
                            '${(show != null ? show.voteAverage * 10 : 80).toStringAsFixed(0)}% Match',
                            style: TextStyle(
                              color: Colors.green[400],
                              fontWeight: FontWeight.w600,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                          Text(
                            show?.firstAirDate.split('-').firstOrNull ?? '2001',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                          Text(
                            "${show?.seasons.length ?? '20'} ${show == null || show.seasons.length > 1 ? "Seasons" : "Season"}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                          Text(
                            "${show?.episodeRunTime.firstOrNull ?? '20'} mins",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.labelSize,
                            ),
                          ),
                          if (show != null &&
                              show.episodeRunTime.isEmpty &&
                              show.lastEpisodeToAir != null)
                            Text(
                              MediaFormatting.formatRuntime(
                                show.lastEpisodeToAir!.runtime,
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppTypography.labelSize,
                              ),
                            ),
                        ],
                      ),
                      if (show?.tagline != null &&
                          show!.tagline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          show.tagline,
                          style: TextStyle(
                            fontSize: AppTypography.bodySize,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        show?.overview ?? 'Show overview...',
                        style: TextStyle(
                          fontSize: AppTypography.bodySize,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              show?.networks.firstOrNull?.name ?? 'Netflix',
                            ),
                          ),
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              show?.status ?? 'Ongoing',
                            ),
                          ),
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              show?.originCountry.firstOrNull ?? 'USA',
                            ),
                          ),
                          Chip(
                            child: Text(
                              style: TextStyle(
                                fontSize: AppTypography.labelSize,
                              ),
                              '\u2605 ${show?.voteAverage.toStringAsFixed(1) ?? 5}',
                            ),
                          ),
                          if (show != null)
                            ...show.genres
                                .take(3)
                                .map(
                                  (g) => Chip(
                                    child: Text(
                                      style: TextStyle(
                                        fontSize: AppTypography.labelSize,
                                      ),
                                      g.name,
                                    ),
                                  ),
                                ),
                          if (show == null) ...[
                            Chip(
                              child: Text(
                                'Horror',
                                style: TextStyle(
                                  fontSize: AppTypography.labelSize,
                                ),
                              ),
                            ),
                            Chip(
                              child: Text(
                                'Comedy',
                                style: TextStyle(
                                  fontSize: AppTypography.labelSize,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 32),
                      Skeleton.keep(
                        child: SeasonDropdown(
                          tvShow: show,
                          selectedSeason: show?.seasons.firstWhereOrNull(
                            (s) => s.seasonNumber == _selectedSeasonNumber,
                          ),
                          onSeasonChanged: (season) {
                            setState(() {
                              _selectedSeasonNumber = season.seasonNumber;
                              _season = TMDB.tvSeason(
                                _resolvedTmdbId!,
                                season.seasonNumber,
                              );
                            });
                          },
                        ),
                      ),
                      FutureBuilder(
                        future: _season,
                        builder: (context, snapshot) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10,
                            children: [
                              if (snapshot.hasData &&
                                  snapshot.data!.episodes.isNotEmpty)
                                PetalButton.outline(
                                  onPressed: () async {
                                    try {
                                      await DownloadManager.enqueueSeason(
                                        tmdbId: _resolvedTmdbId!,
                                        showName: show!.name,
                                        season: snapshot
                                            .data!
                                            .episodes
                                            .first
                                            .seasonNumber,
                                        episodes: snapshot.data!.episodes
                                            .where(
                                              (e) =>
                                                  e.airDate != null &&
                                                  !e.airDate!.isAfter(
                                                    DateTime.now(),
                                                  ),
                                            )
                                            .map((e) => e.episodeNumber)
                                            .toList(),
                                      );
                                      if (context.mounted)
                                        context.push('/downloads');
                                    } catch (_) {
                                      if (context.mounted)
                                        AppNotifications.sendNotification(
                                          const Text('Could not queue season'),
                                          const Text('Please try again.'),
                                        );
                                    }
                                  },
                                  child: const Text('Download season'),
                                ),
                              if (snapshot.hasData &&
                                  snapshot.data!.episodes.isEmpty)
                                Text(
                                  style: TextStyle(
                                    fontSize: AppTypography.bodySize,
                                  ),
                                  'There are no episodes.',
                                ),
                              if (snapshot.hasData &&
                                  snapshot.data!.episodes.isNotEmpty)
                                MediaShelf(
                                  orientation: Orientation.portrait,
                                  cardWidth: 116,
                                  cardHeight: 230,
                                  spacing: 10,
                                  padding: EdgeInsets.zero,
                                  itemCount: snapshot.data!.episodes.length,
                                  itemBuilder: (context, i) => EpisodePortraitCard(
                                    tmdbId: _resolvedTmdbId!,
                                    episode: snapshot.data!.episodes[i],
                                    fallbackImage: show?.posterPath,
                                  ),
                                ),
                            ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      TrailersShelf(videos: show?.videos?.results ?? const []),
                      const SizedBox(height: 20),
                      Skeleton.keep(
                        child: Text(
                          style: TextStyle(fontSize: AppTypography.h4Size),
                          'More Like This',
                        ).h4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations?.length ?? 10,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) =>
                              ShowRecommendationCard(show: recommendations?[i]),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Skeleton.keep(
                        child: Text(
                          style: TextStyle(fontSize: AppTypography.h4Size),
                          'Cast',
                        ).h4,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cast != null ? cast.length : 3,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => CastCard(
                            fallbackIcon: LucideIcons.userRound,
                            member: cast != null ? cast[i] : null,
                          ),
                        ),
                      ),
                      if (_resolvedTmdbId != null) ...[
                        const SizedBox(height: 28),
                        CollapsibleTitleComments(
                          mediaType: 'show',
                          tmdbId: _resolvedTmdbId!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).asSkeleton(enabled: loading);
      },
    );
  }
}
