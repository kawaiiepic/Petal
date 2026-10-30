import 'package:go_router/go_router.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ReleaseTile extends StatelessWidget {
  final UpcomingItem item;

  const ReleaseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => context.push('/series?tmdb=${item.tmdbId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.showName, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                'S${item.season} \u00b7 E${item.episode} - ${item.episodeName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
