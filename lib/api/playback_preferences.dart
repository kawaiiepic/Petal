import 'dart:convert';

import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PlaybackPreferences extends ChangeNotifier {
  static final instance = PlaybackPreferences();
  String audioLanguage = 'en';
  String subtitleLanguage = 'en';
  bool subtitles = true;
  double speed = 1;
  double subtitleDelay = 0;
  double subtitleSize = 32, subtitleOutline = 2, subtitleBottom = 24;
  bool subtitleBackground = true;
  bool _loaded = false;
  Future<void> _writes = Future.value();
  Future<void>? _loading;
  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= () async {
      final revision = _revision;
      try {
        final raw = (await SharedPreferences.getInstance()).getString(
          'player.preferences',
        );
        if (raw != null && revision == _revision) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          audioLanguage = map['audio'] as String? ?? 'en';
          subtitleLanguage = map['subtitle'] as String? ?? 'en';
          subtitles = map['subtitles'] as bool? ?? true;
          subtitleSize = _number(map['subtitleSize'], 32, 12, 64);
          subtitleOutline = _number(map['subtitleOutline'], 2, 0, 6);
          subtitleBottom = _number(map['subtitleBottom'], 24, 0, 240);
          subtitleBackground = map['subtitleBackground'] as bool? ?? true;
          final rate = (map['speed'] as num?)?.toDouble() ?? 1;
          final delay = (map['delay'] as num?)?.toDouble() ?? 0;
          speed = rate.isFinite ? rate.clamp(.25, 3) : 1;
          subtitleDelay = delay.isFinite ? delay.clamp(-60, 60) : 0;
        }
      } catch (_) {}
      _loaded = true;
      notifyListeners();
    }();
  }

  static double _number(
    dynamic value,
    double fallback,
    double min,
    double max,
  ) {
    final n = value is num ? value.toDouble() : fallback;
    return n.isFinite ? n.clamp(min, max) : fallback;
  }

  int _revision = 0;
  Future<void> update({
    String? audio,
    String? subtitle,
    bool? enabled,
    double? rate,
    double? delay,
    double? size,
    double? outline,
    double? bottom,
    bool? background,
  }) {
    _loaded = true;
    _revision++;
    if (audio != null && audio.trim().isNotEmpty)
      audioLanguage = audio.trim().toLowerCase();
    if (subtitle != null && subtitle.trim().isNotEmpty)
      subtitleLanguage = subtitle.trim().toLowerCase();
    if (enabled != null) subtitles = enabled;
    if (rate != null && rate.isFinite) speed = rate.clamp(.25, 3);
    if (delay != null && delay.isFinite) subtitleDelay = delay.clamp(-60, 60);
    if (size != null) subtitleSize = _number(size, 32, 12, 64);
    if (outline != null) subtitleOutline = _number(outline, 2, 0, 6);
    if (bottom != null) subtitleBottom = _number(bottom, 24, 0, 240);
    if (background != null) subtitleBackground = background;
    notifyListeners();
    final raw = jsonEncode({
      'audio': audioLanguage,
      'subtitle': subtitleLanguage,
      'subtitles': subtitles,
      'speed': speed,
      'delay': subtitleDelay,
      'subtitleSize': subtitleSize,
      'subtitleOutline': subtitleOutline,
      'subtitleBottom': subtitleBottom,
      'subtitleBackground': subtitleBackground,
    });
    return _writes = _writes.catchError((Object _) {}).then((_) async {
      await (await SharedPreferences.getInstance()).setString(
        'player.preferences',
        raw,
      );
    });
  }

  Future<void> apply(Player player) async {
    await load();
    await player.setRate(speed);
    final platform = player.platform;
    if (platform is NativePlayer) {
      try {
        await platform.setProperty('sub-delay', subtitleDelay.toString());
      } catch (_) {}
    }
    if (!subtitles) await player.setSubtitleTrack(SubtitleTrack.no());
  }
}
