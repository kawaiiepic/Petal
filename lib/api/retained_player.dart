import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/playback_media_session.dart';
import 'package:petal/models/playback_item.dart';
import 'package:petal/models/stream_item.dart';

class RetainedMedia {
  final PlaybackItem item;
  final StreamItem source;
  final bool finished;
  final double? lastWritten;
  final String? profileKey;
  const RetainedMedia({required this.item, required this.source,
    this.finished = false, this.lastWritten, this.profileKey});
}

/// Owns a single lazy native player for the app. Route leases prevent stale
/// async requests and teardown from taking ownership of a newer session.
class RetainedPlayer {
  RetainedPlayer._();
  static final instance = RetainedPlayer._();
  late final Player player = Player(configuration: PlayerConfiguration());
  late final VideoController controller = VideoController(player,
    configuration: VideoControllerConfiguration());
  late final PlaybackMediaSession mediaSession = PlaybackMediaSession(player);
  final available = ValueNotifier<RetainedMedia?>(null);
  RetainedMedia? loaded;
  int _generation = 0;
  int? _owner;
  String? _profile;
  bool _bound = false;
  Future<void> _tail = Future.value();

  RetainedMedia? get resumable => available.value;
  bool owns(int lease) => _owner == lease;

  void bindAuth() {
    if (_bound) return;
    _bound = true;
    _profile = BackendApi.profileCacheKey;
    BackendApi.authState.addListener(() {
      final next = BackendApi.profileCacheKey;
      if (next == _profile) return;
      _profile = next;
      final hadSession = _owner != null || loaded != null || available.value != null;
      _generation++;
      _owner = null;
      loaded = null;
      available.value = null;
      if (hadSession) unawaited(serialize(() async {
        await controller.pictureInPicture.stop();
        await player.stop();
      }).catchError((Object _) {}));
    });
  }

  Future<void> serialize(Future<void> Function() operation) {
    final task = _tail.then((_) => operation());
    _tail = task.catchError((Object _) {});
    return task;
  }

  int acquire() {
    _owner = ++_generation;
    // Avoid notifying the browsing shell during a route build.
    final lease = _owner!;
    scheduleMicrotask(() {
      if (owns(lease)) available.value = null;
    });
    return lease;
  }

  void release(int lease, RetainedMedia? media) {
    if (!owns(lease)) return;
    _owner = null;
    final generation = _generation;
    loaded = media;
    scheduleMicrotask(() {
      if (_owner == null && generation == _generation) available.value = media;
    });
    unawaited(serialize(() async {
      await controller.pictureInPicture.stop();
      await player.pause();
      if (media == null) await player.stop();
    }).catchError((Object _) {}));
  }

  void dismiss() {
    if (_owner != null) return;
    loaded = null;
    available.value = null;
    unawaited(serialize(() => player.stop()).catchError((Object _) {}));
  }
}
