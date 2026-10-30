import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/home/shelf_poster_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class PosterShelf extends StatefulWidget {
  final String title;
  final List<ShelfItem> items;

  const PosterShelf({super.key, required this.title, required this.items});

  @override
  State<PosterShelf> createState() => _PosterShelfState();
}

class _PosterShelfState extends State<PosterShelf> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: widget.title,
      child: SizedBox(
        height: 23.h,
        child: ScrollableWidget(
          controller: _controller,
          child: ListView.separated(
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 30),
            itemBuilder: (context, index) =>
                ShelfPosterCard(item: widget.items[index]),
          ),
        ),
      ),
    );
  }
}
