import 'package:petal/widgets/home/home_shelf_skeleton.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/models/social/activity_item.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:petal/widgets/social/friend_activity_card.dart';
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
        if (items.isEmpty && snapshot.connectionState != ConnectionState.done) {
          return const HomeShelfSkeleton(
            title: 'Friend activity',
            editorial: true,
            cardHeight: 148,
            orientation: Orientation.landscape,
          );
        }
        return HomeSection(
          title: 'Friend activity',
          editorial: true,
          child: items.isNotEmpty
              ? MediaShelf(
                  orientation: Orientation.landscape,
                  cardHeight: 148,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.take(12).length,
                  itemBuilder: (_, index) =>
                      FriendActivityCard(item: items[index]),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LibraryPanel(
                    child: Row(
                      spacing: 12,
                      children: [
                        const Icon(LucideIcons.users, size: 20),
                        Expanded(
                          child: Text(
                            snapshot.hasError
                                ? 'Couldn’t load friend activity.'
                                : 'Nothing new from friends yet.',
                          ),
                        ),
                        if (snapshot.hasError)
                          Button.ghost(
                            onPressed: () =>
                                setState(() => _future = SocialApi.activity()),
                            child: const Text('Retry'),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
