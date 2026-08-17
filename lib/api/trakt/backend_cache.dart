import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/models/media_state.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class BackendCache {
  static var continueWatching = ValueChangeNotifier<List<ContinueWatchingItem>>([]);

  static Future<void> fetchContinueWatching() async {
    final watching = await BackendApi.continueWatching();
    continueWatching.value = watching;
  }
}
