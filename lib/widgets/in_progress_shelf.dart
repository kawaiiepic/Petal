import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/widgets/home/continue_watching_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class InProgressShelf extends StatefulWidget {
  const InProgressShelf({super.key});

  @override
  State<InProgressShelf> createState() => _InProgressShelfState();
}

class _InProgressShelfState extends State<InProgressShelf> {
  @override
  void initState() {
    super.initState();
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
          child: MediaShelf(
            orientation: Orientation.landscape,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final state = list[index];
              return ContinueWatchingCard(
                key: ValueKey('${state.mediaType}-${state.tmdbId}'),
                state: state,
              );
            },
          ),
        );
      },
    );
  }
}
