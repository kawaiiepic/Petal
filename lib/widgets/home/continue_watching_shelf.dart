import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/widgets/home/continue_watching_card.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sizer/sizer.dart';

class ContinueWatchingShelf extends StatefulWidget {
  const ContinueWatchingShelf({super.key});

  @override
  State<StatefulWidget> createState() => _ContinueWatchingShelfState();
}

class _ContinueWatchingShelfState extends State<ContinueWatchingShelf> {
  late final ScrollController _controller;
  bool _open = true;

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
    final style = TextStyle(
      fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 16.sp,
    );
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, child) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            Button(
              style: ButtonVariance.ghost,
              onPressed: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Continue Watching',
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Icon(
                      _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              SizedBox(
                height: 25.h,
                child: ScrollableWidget(
                  controller: _controller,
                  offset: -25,
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    key: const PageStorageKey<String>(
                      'unique_key_for_this_list',
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final state = list[index];
                      return ContinueWatchingCard(
                        key: ValueKey('${state.mediaType}-${state.tmdbId}'),
                        state: state,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
