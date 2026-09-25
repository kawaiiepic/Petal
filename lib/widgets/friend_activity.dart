import 'package:go_router/go_router.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FriendActivity extends StatefulWidget {
  const FriendActivity({super.key});

  @override
  State<FriendActivity> createState() => _FriendActivityState();
}

class _FriendActivityState extends State<FriendActivity> {
  late Future<List<ActivityItem>> _future = SocialApi.activity();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ActivityItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Friend activity',
          child: Column(
            children: [
              for (final item in items.take(8))
                Button.ghost(
                  alignment: Alignment.centerLeft,
                  onPressed: () => context.push('/profile/${item.profileId}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _ActivityLine(item: item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityLine extends StatelessWidget {
  final ActivityItem item;

  const _ActivityLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.mediaType != 'movie';
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final title = snapshot.hasData
            ? (isShow ? (snapshot.data as dynamic).name as String? : (snapshot.data as dynamic).title as String?)
            : null;
        return Text('${item.name} watched ${title ?? (isShow ? 'a show' : 'a movie')}');
      },
    );
  }
}
