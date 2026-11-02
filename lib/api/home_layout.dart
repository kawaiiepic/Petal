import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeLayout extends ChangeNotifier {
  static final instance = HomeLayout();
  static const labels = <String, String>{
    'surprise': 'Surprise me',
    'stats': 'Statistics',
    'upcoming': 'Upcoming',
    'deck': 'On Deck',
    'start': 'Start now',
    'watchlist': 'Watchlist',
    'liked': 'Liked',
    'recent': 'Recently watched',
    'stalled': 'Stalled',
    'rewatched': 'Most rewatched',
    'because': 'Because you watched',
    'catalogs': 'Addon catalogs',
    'downloads': 'Downloads',
    'friends': 'Friends',
    'calendar': 'Release calendar',
  };
  List<String> order = labels.keys.toList();
  Set<String> hidden = {'start'};
  bool _loaded = false;
  int _revision = 0;
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= () async {
      final revision = _revision;
      try {
        final raw = (await SharedPreferences.getInstance()).getString(
          'home.layout',
        );
        if (raw != null && revision == _revision) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          order = [
            ...(map['order'] as List)
                .whereType<String>()
                .where(labels.containsKey)
                .toSet(),
            ...labels.keys.where((id) => !(map['order'] as List).contains(id)),
          ];
          hidden = (map['hidden'] as List)
              .whereType<String>()
              .where(labels.containsKey)
              .toSet();
        }
      } catch (_) {}
      _loaded = true;
      notifyListeners();
    }();
  }

  Future<void> setVisible(String id, bool visible) {
    if (visible) {
      hidden.remove(id);
    } else {
      hidden.add(id);
    }
    return _save();
  }

  Future<void> move(String id, int delta) {
    final index = order.indexOf(id);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= order.length) return Future.value();
    order.removeAt(index);
    order.insert(next, id);
    return _save();
  }

  Future<void> reset() {
    order = labels.keys.toList();
    hidden = {'start'};
    return _save();
  }

  Future<void> _save() {
    _revision++;
    _loaded = true;
    notifyListeners();
    final raw = jsonEncode({'order': order, 'hidden': hidden.toList()});
    return _writes = _writes.catchError((Object _) {}).then((_) async {
      await (await SharedPreferences.getInstance()).setString(
        'home.layout',
        raw,
      );
    });
  }
}
