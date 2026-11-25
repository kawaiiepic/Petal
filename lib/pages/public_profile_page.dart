import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/models/social/social_profile.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/group_watch_history.dart';
import 'package:petal/utils/history_timeline.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/profile/public_history_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PublicProfilePage extends StatefulWidget {
  final String profileId;
  const PublicProfilePage({super.key, required this.profileId});
  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  SocialProfile? _profile;
  List<WatchHistoryItem> _history = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _historyError;
  MediaType? _filter;
  int _generation = 0;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(covariant PublicProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _profile = null; _history = const []; _loading = true;
      _busy = false; _filter = null; _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final id = widget.profileId;
    try {
      final profile = await SocialApi.profile(id);
      if (!mounted || generation != _generation) return;
      if (profile == null) throw StateError('Profile unavailable');
      setState(() { _profile = profile; _error = null; });
      try {
        final response = await BackendApi.dio.get('${Api.ServerUrl}/track/states/$id');
        final rows = response.data['result'] as List? ?? const [];
        final history = groupWatchHistory(rows.map((e) =>
          WatchHistoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList());
        if (!mounted || generation != _generation) return;
        setState(() { _history = history; _historyError = null; _loading = false; });
      } catch (_) {
        if (mounted && generation == _generation) setState(() {
          _historyError = 'Watch history is unavailable.'; _loading = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) setState(() {
        _error = 'Could not load profile.'; _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (profile.following) { await SocialApi.unfollow(profile.id); }
      else { await SocialApi.follow(profile.id); }
      if (mounted && widget.profileId == profile.id) await _load();
    } catch (_) {
      if (mounted && widget.profileId == profile.id) setState(() => _error = 'Could not update follow status.');
    } finally {
      if (mounted && widget.profileId == profile.id) setState(() => _busy = false);
    }
  }

  Widget _avatar(SocialProfile profile, double size) {
    final initials = profile.name.isEmpty ? '?' : profile.name[0].toUpperCase();
    final avatar = profile.avatar;
    if (avatar == null || avatar.isEmpty) return Avatar(size: size, initials: initials);
    final url = avatar.startsWith('http') ? avatar : '${Api.ProfileUrl}/$avatar';
    return CachedNetworkImage(imageUrl: url,
      imageBuilder: (_, provider) => Avatar(size: size, initials: initials, provider: provider),
      placeholder: (_, _) => Avatar(size: size, initials: initials),
      errorWidget: (_, _, _) => Avatar(size: size, initials: initials));
  }

  Widget _stat(int value, String label) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text('$value', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
    Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.mutedForeground)),
  ]);

  Widget _filterButton(MediaType? type, String label) {
    void select() => setState(() => _filter = type);
    return _filter == type ? PetalButton.primary(onPressed: select, child: Text(label))
      : PetalButton.secondary(onPressed: select, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final compact = TvLayout.isCompact(context);
    final colors = Theme.of(context).colorScheme;
    final me = BackendApi.authState.selectedProfile?.id;
    final profile = _profile;
    final plays = historyTimeline(_history);
    final movies = plays.where((p) => p.item.mediaType == MediaType.movie).length;
    final episodes = plays.where((p) => p.item.mediaType == MediaType.show).length;
    final shows = plays.where((p) => p.item.mediaType == MediaType.show).map((p) => p.item.tmdbId).toSet().length;
    final filtered = plays.where((p) => _filter == null || p.item.mediaType == _filter).toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.viewPaddingOf(context).top)),
      if (profile == null)
        SliverFillRemaining(hasScrollBody: false, child: Center(child: _loading
          ? const PetalActivityIndicator()
          : Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
            Text(_error ?? 'Profile unavailable'),
            PetalButton.secondary(onPressed: () { setState(() => _loading = true); _load(); },
              child: const Text('Try again')),
          ])))
      else ...[
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Row(spacing: compact ? 16 : 28, children: [
            _avatar(profile, compact ? 96 : 144),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 9, children: [
              Text('PROFILE', style: TextStyle(fontSize: 11, letterSpacing: 1.8,
                fontWeight: FontWeight.w700, color: colors.mutedForeground)),
              Text(profile.name, style: TextStyle(fontSize: compact ? 30 : 48,
                fontWeight: FontWeight.w800, height: 1.05)),
              if (me == profile.id) Text('Your profile', style: TextStyle(color: colors.mutedForeground))
              else if (me != null) profile.following
                ? PetalButton.secondary(onPressed: _busy ? null : _toggleFollow,
                    leading: const Icon(LucideIcons.check, size: 16), child: const Text('Following'))
                : PetalButton.primary(onPressed: _busy ? null : _toggleFollow,
                    child: const Text('Follow')),
            ])),
          ]))),
        if (_error != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!))),
        if (_loading) const SliverToBoxAdapter(child: Center(child: PetalActivityIndicator()))
        else if (_historyError != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20),
          child: Column(spacing: 10, children: [Text(_historyError!),
            PetalButton.secondary(onPressed: _load, child: const Text('Retry'))])))
        else ...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _stat(movies, 'Movie plays')),
              Expanded(child: _stat(shows, 'TV shows')),
              Expanded(child: _stat(episodes, 'Episode plays')),
            ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text('Watch history', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _filterButton(null, 'All'), _filterButton(MediaType.movie, 'Movies'), _filterButton(MediaType.show, 'TV Shows'),
            ]))),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Text('No public watch history for this filter.')))
          else SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: compact ? 145 : 165, mainAxisSpacing: 14,
              crossAxisSpacing: 12, childAspectRatio: .55),
              itemCount: filtered.length,
              itemBuilder: (_, i) => PublicHistoryCard(key: ValueKey(filtered[i].key), play: filtered[i]))),
        ],
      ],
      SliverToBoxAdapter(child: SizedBox(height: 32 + MediaQuery.viewPaddingOf(context).bottom + (compact ? 82 : 0))),
    ]);
  }
}
