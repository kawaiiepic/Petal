import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:petal/utils/show_playback.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Shared featured actions for both carousel layouts.
class FeaturedDetailsButton extends StatefulWidget {
  const FeaturedDetailsButton({super.key, required this.item});
  final CatalogItem item;
  @override
  State<FeaturedDetailsButton> createState() => _FeaturedDetailsButtonState();
}

class _FeaturedDetailsButtonState extends State<FeaturedDetailsButton> {
  late Future<int> _identity = _resolve(widget.item);
  bool _busy = false;
  int _revision = 0;

  static Future<int> _resolve(CatalogItem item) async {
    final numeric = int.tryParse(item.id);
    if (numeric != null && numeric > 0) return numeric;
    final result = await ApiCache.getTmdbSearch(item.id);
    if (item.type == 'movie' && result.movies.isNotEmpty) return result.movies.first.id;
    if (item.type != 'movie' && result.tv.isNotEmpty) return result.tv.first.id;
    throw StateError('Title not found.');
  }

  @override
  void didUpdateWidget(covariant FeaturedDetailsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id || oldWidget.item.type != widget.item.type) {
      _revision++;
      _busy = false;
      _identity = _resolve(widget.item);
    }
  }

  MediaType get _type => widget.item.type == 'movie' ? MediaType.movie : MediaType.show;

  void _details() {
    final item = widget.item;
    final type = item.type == 'movie' ? 'movie' : 'series';
    final key = int.tryParse(item.id) == null ? 'imdb' : 'tmdb';
    context.push('/$type?$key=${Uri.encodeQueryComponent(item.id)}');
  }

  Future<void> _play() async {
    if (_busy) return;
    final revision = _revision;
    final profile = BackendApi.profileCacheKey;
    final type = _type;
    bool current() => mounted && revision == _revision &&
        profile == BackendApi.profileCacheKey && (ModalRoute.isCurrentOf(context) ?? true);
    setState(() => _busy = true);
    try {
      final id = await _identity;
      await Future.wait([
        BackendCache.fetchWatchHistory().catchError((Object _) {}),
        BackendCache.fetchContinueWatching().catchError((Object _) {}),
      ]);
      if (!current()) return;
      if (type == MediaType.movie) {
        final completion = WatchProgress.playbackCompletion(
          tmdbId: id, type: type, history: BackendCache.watchHistory.value,
          nextUp: BackendCache.continueWatching.value) ?? 0.0;
        final progress = WatchProgress.isPartial(completion) ? completion : 0.0;
        await context.push('/player?media=$id&p=$progress');
      } else {
        final show = await TMDB.tvShow(id);
        final target = await ShowPlayback.resolve(show: show,
          history: [...BackendCache.watchHistory.value],
          nextUp: [...BackendCache.continueWatching.value],
          loadSeason: (number) => TMDB.tvSeason(id, number));
        if (!current()) return;
        final ep = target.episode;
        if (ep == null) throw StateError('No aired episodes are available.');
        if (target.rewatch) await HistoryActions.startTitleRewatch(id, type);
        if (!current()) return;
        final completion = WatchProgress.playbackCompletion(
          tmdbId: id, type: type, history: BackendCache.watchHistory.value,
          nextUp: BackendCache.continueWatching.value,
          season: ep.seasonNumber, episode: ep.episodeNumber) ?? 0.0;
        final progress = !target.rewatch && WatchProgress.isPartial(completion) ? completion : 0.0;
        await context.push('/player?media=$id&s=${ep.seasonNumber}&e=${ep.episodeNumber}&p=$progress');
      }
    } catch (error) {
      if (current()) AppNotifications.sendNotification(
        const Text('Could not start playback'), Text(HistoryActions.errorMessage(error)));
    } finally {
      if (mounted && revision == _revision) setState(() => _busy = false);
    }
  }

  Widget _button({required String label, required IconData icon, required VoidCallback? onTap,
      bool primary = false, bool iconOnly = false, bool loading = false}) {
    final color = primary ? const Color(0xFF17171A) : Colors.white;
    return glass.GlassButton.custom(
      label: label, height: 44, width: iconOnly ? 44 : null,
      enabled: onTap != null, onTap: onTap ?? () {},
      useOwnLayer: true,
      shape: const glass.LiquidRoundedSuperellipse(borderRadius: 22),
      surfaceStyle: glass.GlassSurfaceStyle.solid,
      color: primary ? const Color(0xFFF7F7F8) : const Color(0x66333333),
      style: glass.GlassButtonStyle.filled,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 12),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
          if (loading) PetalActivityIndicator(size: 16, color: color)
          else Icon(icon, size: 16, color: color),
          if (!iconOnly) Text(label, style: TextStyle(color: color,
            fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 390;
      return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        _button(label: 'Play Now', icon: LucideIcons.play, primary: true,
          loading: _busy, onTap: _busy ? null : _play),
        FutureBuilder(future: _identity, builder: (context, snapshot) {
          final id = snapshot.data;
          return ValueListenableBuilder(valueListenable: UserLibrary.watchlist,
            builder: (context, _, _) {
              final saved = id != null && UserLibrary.isInWatchlist(id, _type);
              return _button(label: saved ? 'Watchlisted' : 'Watchlist',
                icon: saved ? LucideIcons.check : LucideIcons.plus,
                iconOnly: compact,
                onTap: id == null ? null : () => UserLibrary.toggleWatchlist(
                  id, _type, name: widget.item.name));
            });
        }),
        _button(label: 'Details', icon: LucideIcons.info, iconOnly: compact, onTap: _details),
      ]);
    });
  }
}
