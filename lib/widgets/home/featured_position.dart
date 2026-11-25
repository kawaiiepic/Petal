import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/models/catalog_item.dart';

/// Session-local selection shared by the mobile and desktop featured heroes.
abstract final class FeaturedPosition {
  static final _selected = <String?, (String, String)>{};

  static int restore(List<CatalogItem> items) {
    final key = _selected[BackendApi.profileCacheKey];
    if (key == null) return 0;
    final index = items.indexWhere((item) => (item.type, item.id) == key);
    return index < 0 ? 0 : index;
  }

  static void remember(CatalogItem item) {
    _selected[BackendApi.profileCacheKey] = (item.type, item.id);
  }
}
