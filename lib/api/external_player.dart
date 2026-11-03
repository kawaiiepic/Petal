import 'package:flutter/foundation.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/external_playback_session.dart';
import 'package:petal/app/petal_app.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/external_playback_request.dart';
import 'package:petal/models/stream_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalPlayer {
  static final _session = ExternalPlaybackSession(
    profileKey: () => BackendApi.profileCacheKey,
    confirm: (request) async {
      final context = PetalApp.rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return null;
      return showOverlay<bool>(
        context,
        DialogConfiguration(),
        builder: (context) => AlertDialog(
          title: Text(
            request.episode == null
                ? 'Finished watching?'
                : 'Finished this episode?',
          ),
          content: Text(
            '${request.label}\n\nMark it watched only if you saw at least 90%.',
          ),
          actions: [
            SecondaryButton(
              onPressed: () => closeOverlay(context, false),
              child: const Text('Not yet'),
            ),
            PrimaryButton(
              onPressed: () => closeOverlay(context, true),
              child: const Text('Yes, mark watched'),
            ),
          ],
        ),
      ).future;
    },
    markWatched: (request) => BackendApi.setProgress(
      request.mediaId,
      request.type,
      1,
      season: request.episode?.seasonNumber,
      episode: request.episode?.episodeNumber,
    ),
  );

  static Future<bool> openTracked({
    required StreamItem stream,
    required int mediaId,
    Episode? episode,
    String? label,
  }) => _session.begin(
    request: ExternalPlaybackRequest(
      mediaId: mediaId,
      episode: episode,
      label: label ?? stream.title,
      profileKey: BackendApi.profileCacheKey,
    ),
    open: () => stream.external
        ? launchUrl(Uri.parse(stream.url), mode: LaunchMode.externalApplication)
        : open(stream.url),
  );
  static const prefsKey = 'external_player';

  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
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
        return Uri.parse(
          'intent:$withoutScheme#Intent;scheme=https;type=video/*;package=com.mxtech.videoplayer.ad;end',
        );
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
      return launchUrl(
        Uri.parse(streamUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
