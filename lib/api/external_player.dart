import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalPlayer {
  static const prefsKey = 'external_player';

  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<String> selected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKey) ?? 'Disabled';
  }

  static Future<bool> isEnabled() async {
    if (!isMobile) return false;
    final value = await selected();
    return value != 'Disabled';
  }

  static Uri? _uriFor(String player, String streamUrl) {
    final encoded = Uri.encodeComponent(streamUrl);
    switch (player) {
      case 'Outplayer':
        return Uri.parse('outplayer://x-callback-url/play?url=$encoded');
      case 'MX Player':
        final withoutScheme = streamUrl.replaceFirst(RegExp(r'^https?:'), '');
        return Uri.parse('intent:$withoutScheme#Intent;scheme=https;type=video/*;package=com.mxtech.videoplayer.ad;end');
      default:
        return null;
    }
  }

  static Future<bool> open(String streamUrl) async {
    if (!await isEnabled()) return false;
    final player = await selected();
    final uri = _uriFor(player, streamUrl);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return launchUrl(Uri.parse(streamUrl), mode: LaunchMode.externalApplication);
    }
  }
}
