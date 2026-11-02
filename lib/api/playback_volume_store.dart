import 'package:shared_preferences/shared_preferences.dart';

/// Device-local volume, shared by internal player sessions (including downloads).
class PlaybackVolumeStore {
  static final instance = PlaybackVolumeStore();
  static const volumeKey = 'player.volume';
  static const audibleKey = 'player.audibleVolume';
  final Future<SharedPreferences> Function() _preferences;
  double? _value;
  double _audible = 100;
  int _revision = 0;
  Future<double>? _loading;
  Future<void> _writes = Future.value();

  PlaybackVolumeStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  double? get value => _value;
  double get audibleVolume => _audible;
  int get revision => _revision;
  double _normalise(double value) =>
      value.isFinite ? value.clamp(0.0, 100.0) : 100;

  Future<double> load() {
    if (_value != null) return Future.value(_value);
    return _loading ??= () async {
      final revision = _revision;
      try {
        final prefs = await _preferences();
        if (revision == _revision) {
          _value = _normalise(prefs.getDouble(volumeKey) ?? 100);
          _audible = _normalise(
            prefs.getDouble(audibleKey) ?? (_value! > 0 ? _value! : 100),
          );
          if (_audible == 0) _audible = 100;
        }
      } catch (_) {
        _value ??= 100;
      }
      return _value ?? 100.0;
    }();
  }

  Future<void> save(double volume) {
    final value = _normalise(volume);
    _value = value;
    if (value > 0) _audible = value;
    final audible = _audible;
    _revision++;
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final prefs = await _preferences();
      await prefs.setDouble(volumeKey, value);
      await prefs.setDouble(audibleKey, audible);
    });
    return _writes;
  }
}
