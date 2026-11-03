import 'package:petal/api/backend/backend_api.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'dart:convert';

import 'package:petal/models/watch_session.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WatchPresenceClient {
  final String baseUrl = "wss://petal-backend.blossomvale.dev/ws";
  final String? profileId;

  WebSocketChannel? _channel;
  bool _disposed = false;
  int _generation = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  StreamSubscription? _sub;

  final _sessionsController = StreamController<List<WatchSession>>.broadcast();
  Stream<List<WatchSession>> get sessions => _sessionsController.stream;

  WatchPresenceClient({this.profileId});

  void connect() { unawaited(_connect()); }

  Future<void> _connect() async {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    final generation = ++_generation;
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: profileId == null ? null : {'profileId': profileId!});
      final cookies = await BackendApi.cookieJar.loadForRequest(uri.replace(scheme: 'https'));
      if (_disposed || generation != _generation) return;
      if (!cookies.any((cookie) => cookie.name == 'auth')) { _scheduleReconnect(); return; }
      await _sub?.cancel();
      await _channel?.sink.close();
      if (_disposed || generation != _generation) return;
      final channel = IOWebSocketChannel.connect(uri, headers: {
        'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
      });
      _channel = channel;
      _sub = channel.stream.listen((raw) {
        if (_disposed || generation != _generation) return;
        try {
          final msg = jsonDecode(raw as String);
          if (msg['type'] == 'sessions') {
            _sessionsController.add((msg['sessions'] as List)
                .map((s) => WatchSession.fromJson(Map<String, dynamic>.from(s as Map))).toList());
          }
        } catch (_) {}
      }, onError: (_) { if (generation == _generation) _scheduleReconnect(); },
         onDone: () { if (generation == _generation) _scheduleReconnect(); });
      await channel.ready;
    } catch (_) { if (!_disposed && generation == _generation) _scheduleReconnect(); }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  void sendHeartbeat({
    required int tmdbId,
    required String mediaType,
    int? season,
    int? episode,
    required int position,
    required int duration,
    String? title,
    String? episodeTitle,
  }) {
    _channel?.sink.add(
      jsonEncode({
        'type': 'heartbeat',
        'profileId': profileId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
        'title': title ?? 'Media $tmdbId',
        'episodeTitle': episodeTitle,
        'season': season,
        'episode': episode,
        'position': position,
        'duration': duration,
      }),
    );
  }

  void sendStop() {
    _channel?.sink.add(jsonEncode({'type': 'stop', 'profileId': profileId}));
  }

  void startHeartbeatLoop({
    required int tmdbId,
    required String mediaType,
    int? season,
    int? episode,
    required int Function() getPosition,
    required int Function() getDuration,
    Duration interval = const Duration(seconds: 10),
  }) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      sendHeartbeat(
        tmdbId: tmdbId,
        mediaType: mediaType,
        season: season,
        episode: episode,
        position: getPosition(),
        duration: getDuration(),
      );
    });
  }

  void stopHeartbeatLoop() {
    _heartbeatTimer?.cancel();
    sendStop();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _sessionsController.close();
  }
}
