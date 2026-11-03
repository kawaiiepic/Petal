import 'package:petal/widgets/home/home_shelf_skeleton.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/home/shelf_poster_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PosterShelf extends StatelessWidget {
  final String title;
  final List<ShelfItem> items;
  final bool loading;
  const PosterShelf({super.key, required this.title, required this.items, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) return HomeShelfSkeleton(title: title);
    if (items.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: title,
      child: MediaShelf(
        itemCount: items.length,
        itemBuilder: (context, index) => ShelfPosterCard(item: items[index]),
      ),
    );
  }
}
