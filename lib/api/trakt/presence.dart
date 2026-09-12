import 'dart:async';
import 'dart:convert';

import 'package:petal/models/session.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WatchPresenceClient {
  final String baseUrl = "wss://petal-backend.blossomvale.dev/ws";
  final String? profileId;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  StreamSubscription? _sub;

  final _sessionsController = StreamController<List<WatchSession>>.broadcast();
  Stream<List<WatchSession>> get sessions => _sessionsController.stream;

  WatchPresenceClient({this.profileId});

  void connect() {
    final uri = profileId != null ? Uri.parse('$baseUrl?profileId=$profileId') : Uri.parse(baseUrl);

    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen(
      (raw) {
        final msg = jsonDecode(raw as String);
        if (msg['type'] == 'sessions') {
         _sessionsController.add((msg['sessions'] as List).map((s) => WatchSession.fromJson(s as Map<String, dynamic>)).toList());
        }
      },
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  void sendHeartbeat({required int tmdbId, required String mediaType, int? season, int? episode, required int position, required int duration}) {
    _channel?.sink.add(
      jsonEncode({
        'type': 'heartbeat',
        'profileId': profileId,
        'tmdbId': tmdbId,
        'mediaType': mediaType,
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
      sendHeartbeat(tmdbId: tmdbId, mediaType: mediaType, season: season, episode: episode, position: getPosition(), duration: getDuration());
    });
  }

  void stopHeartbeatLoop() {
    _heartbeatTimer?.cancel();
    sendStop();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _sessionsController.close();
  }
}
