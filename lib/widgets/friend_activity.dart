import 'package:petal/api/social_api.dart';
import 'package:petal/models/social/activity_item.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/social/friend_activity_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

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
          child: SizedBox(
            height: 22.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.take(12).length,
              itemBuilder: (context, index) =>
                  FriendActivityCard(item: items[index]),
            ),
          ),
        );
      },
    );
  }
}
