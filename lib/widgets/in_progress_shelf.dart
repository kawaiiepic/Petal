import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
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
    _onAuth();
    BackendApi.authState.addListener(_onAuth);
  }

  void _onAuth() {
    if (BackendApi.authState.selectedProfile != null) {
      BackendCache.fetchContinueWatching();
    }
  }

  @override
  void dispose() {
    BackendApi.authState.removeListener(_onAuth);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        if (list.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Continue Watching',
          child: SizedBox(
            height: 25.h,
            child: ScrollableWidget(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final state = list[index];
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
