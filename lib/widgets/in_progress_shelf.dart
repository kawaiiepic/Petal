import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:petal/widgets/trakt/trakt_next_up.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class InProgressShelf extends StatefulWidget {
  const InProgressShelf({super.key});

  @override
  State<InProgressShelf> createState() => _InProgressShelfState();
}

class _InProgressShelfState extends State<InProgressShelf> {
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

  bool _started(ContinueWatchingItem item) {
    if (item is MovieItem) return item.completion > 0 && item.completion < 1;
    if (item is ShowItem) {
      final next = item.nextEpisode;
      return next != null && next.completion > 0 && next.completion < 1;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        final visible = list.where(_started).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Continue Watching',
          child: SizedBox(
            height: 25.h,
            child: ScrollableWidget(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final state = visible[index];
                  return SizedBox(
                    width: 55.w,
                    child: TraktNextUpItem(key: ValueKey('${state.mediaType}-${state.tmdbId}'), state: state),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
