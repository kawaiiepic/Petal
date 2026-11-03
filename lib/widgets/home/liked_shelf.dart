import 'package:petal/api/user_library.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/poster_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LikedShelf extends StatelessWidget {
  const LikedShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserLibrary.ratings,
      builder: (context, _, __) {
        final items = UserLibrary.ratedTitles()
            .take(12)
            .map(
              (t) => ShelfItem(
                tmdbId: t.tmdbId,
                type: t.type,
                subtitle: t.rating == TitleRating.love ? 'Loved' : 'Liked',
              ),
            )
            .toList();
        return PosterShelf(title: 'Liked', items: items);
      },
    );
  }
}
