import 'package:flutter/widgets.dart';
import 'package:petal/models/external_playback_request.dart';

/// Tracks the actual app round-trip, not merely completion of launchUrl().
class ExternalPlaybackSession with WidgetsBindingObserver {
  final Future<bool?> Function(ExternalPlaybackRequest) confirm;
  final Future<void> Function(ExternalPlaybackRequest) markWatched;
  final String? Function() profileKey;
  final void Function(Object)? onError;
  ExternalPlaybackSession({
    required this.confirm,
    required this.markWatched,
    required this.profileKey,
    this.onError,
  });

  ExternalPlaybackRequest? _pending;
  bool _launched = false;
  bool _left = false;
  bool _returned = false;
  bool _prompting = false;

  Future<bool> begin({
    required ExternalPlaybackRequest request,
    required Future<bool> Function() open,
  }) async {
    if (_pending != null) return true;
    _pending = request;
    _launched = _left = _returned = _prompting = false;
    WidgetsBinding.instance.addObserver(this);
    try {
      final launched = await open();
      if (!identical(_pending, request)) return false;
      _launched = launched;
      if (!_launched) {
        _clear(request);
        return false;
      }
      _maybeConfirm();
      return true;
    } catch (_) {
      _clear(request);
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_pending == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden)
      _left = true;
    if (state == AppLifecycleState.resumed && _left) _returned = true;
    _maybeConfirm();
  }

  void _maybeConfirm() {
    final request = _pending;
    if (request == null || !_launched || !_left || !_returned || _prompting)
      return;
    _prompting = true;
    Future<void>(() async {
      try {
        if (request.profileKey == null || request.profileKey != profileKey())
          return;
        final finished = await confirm(request);
        if (finished == true && request.profileKey == profileKey())
          await markWatched(request);
      } catch (error) {
        onError?.call(error);
      } finally {
        _clear(request);
      }
    });
  }

  void _clear([ExternalPlaybackRequest? expected]) {
    if (expected != null && !identical(_pending, expected)) return;
    WidgetsBinding.instance.removeObserver(this);
    _pending = null;
  }

  void dispose() => _clear();
}
