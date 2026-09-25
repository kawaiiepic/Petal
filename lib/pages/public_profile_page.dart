import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/back_button.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await SocialApi.profile(widget.profileId);
      final response = await BackendApi.dio.get('${Api.ServerUrl}/track/states/${widget.profileId}');
      final rows = response.data['result'] as List? ?? const [];
      final history = rows.map((e) => WatchHistoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null) return;
    setState(() => _busy = true);
    try {
      if (profile.following) {
        await SocialApi.unfollow(profile.id);
      } else {
        await SocialApi.follow(profile.id);
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = BackendApi.authState.selectedProfile?.id;
    return Scaffold(
      headers: [
        AppBar(leading: const [BackButton()], title: Text(_profile?.name ?? 'Profile')),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    Avatar(size: 56, initials: (_profile?.name ?? '?')[0]),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_profile?.name ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                    if (me != widget.profileId)
                      Button.primary(
                        onPressed: _busy ? null : _toggleFollow,
                        child: Text(_profile?.following == true ? 'Following' : 'Follow'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Watch history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_history.isEmpty) const Text('No public watch history yet.') else for (final item in _history.take(40)) _HistoryTile(item: item),
              ],
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WatchHistoryItem item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.mediaType == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final name = snapshot.hasData
            ? (isShow ? (snapshot.data as dynamic).name as String? : (snapshot.data as dynamic).title as String?)
            : null;
        return Button.ghost(
          alignment: Alignment.centerLeft,
          onPressed: () => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(name ?? (isShow ? 'Show ${item.tmdbId}' : 'Movie ${item.tmdbId}')),
          ),
        );
      },
    );
  }
}
