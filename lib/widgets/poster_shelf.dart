import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/home/shelf_poster_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PosterShelf extends StatelessWidget {
  final String title;
  final List<ShelfItem> items;
  const PosterShelf({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
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
