import 'package:petal/pages/player/overlay/player_glass_panel.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/timed_comments_api.dart';
import 'package:petal/models/social/timed_comment.dart';
import 'package:petal/utils/media_formatting.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class TimedCommentsOverlay extends StatefulWidget {
  final Player player;
  final int mediaId;
  final int? season;
  final int? episode;
  final ValueNotifier<List<Duration>>? markers;

  const TimedCommentsOverlay({
    super.key,
    required this.player,
    required this.mediaId,
    this.season,
    this.episode,
    this.markers,
  });

  @override
  TimedCommentsOverlayState createState() => TimedCommentsOverlayState();
}

class TimedCommentsOverlayState extends State<TimedCommentsOverlay> {
  List<TimedComment> _comments = const [];
  List<TimedComment> _visible = const [];
  StreamSubscription<Duration>? _positionSub;
  int _generation = 0;
  bool _enabled = true;
  bool _opening = false;

  TimedCommentsApi get _api => TimedCommentsApi(
    widget.mediaId,
    season: widget.season,
    episode: widget.episode,
  );

  @override
  void initState() {
    super.initState();
    _attach();
    unawaited(_load());
  }

  void _publishMarkers() {
    final positions = _enabled
        ? (_comments.map((comment) => comment.position).toSet().toList()..sort())
        : <Duration>[];
    widget.markers?.value = List.unmodifiable(positions);
  }

  void _attach() {
    _positionSub = widget.player.stream.position.listen(_updateVisible);
  }

  @override
  void didUpdateWidget(covariant TimedCommentsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _positionSub?.cancel();
      _attach();
    }
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.season != widget.season ||
        oldWidget.episode != widget.episode ||
        oldWidget.player != widget.player) {
      _comments = const [];
      _visible = const [];
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    if (BackendApi.authState.selectedProfile == null) return;
    try {
      final comments = await _api.list(
        cancelled: () => !mounted || generation != _generation,
      );
      if (!mounted || generation != _generation) return;
      // Preserve comments posted while the initial request was running.
      final merged = {for (final comment in comments) comment.id: comment,
        for (final comment in _comments) comment.id: comment};
      _comments = merged.values.toList()..sort(_compare);
      _publishMarkers();
      _updateVisible(widget.player.state.position);
    } catch (_) {
      // Social features must never interrupt playback. The composer can retry.
    }
  }

  static int _compare(TimedComment a, TimedComment b) {
    final time = a.position.compareTo(b.position);
    return time != 0 ? time : a.id.compareTo(b.id);
  }

  void _updateVisible(Duration position) {
    if (!mounted) return;
    final next = _enabled
        ? visibleTimedComments(_comments, position)
        : const <TimedComment>[];
    if (next.length == _visible.length &&
        List.generate(next.length, (i) => next[i].id == _visible[i].id)
            .every((same) => same)) return;
    setState(() => _visible = next);
  }

  Future<void> openComposer({Offset? anchor}) async {
    if (_opening) return;
    if (BackendApi.authState.selectedProfile == null) {
      showToast(context: context, builder: (_, _) =>
          const Text('Sign in and select a profile to post timed comments.'),
          location: ToastLocation.bottomLeft);
      return;
    }
    final state = widget.player.state;
    if (state.duration <= Duration.zero ||
        state.position < Duration.zero ||
        state.position > state.duration) return;
    final position = state.position;
    final api = _api;
    _opening = true;
    try {
      await showPlayerGlassPanel<void>(
        context,
        anchor: anchor,
        title: 'Timed comment · ${MediaFormatting.fmt(position)}',
        builder: (context) => _TimedCommentComposer(
          position: position,
          enabled: _enabled,
          onToggle: (enabled) {
            if (!mounted || widget.mediaId != api.mediaId ||
                widget.season != api.season || widget.episode != api.episode) return;
            _enabled = enabled;
            _publishMarkers();
            _updateVisible(widget.player.state.position);
            if (enabled) unawaited(_load());
          },
          onPost: (body) async {
            if (!mounted || widget.mediaId != api.mediaId ||
                widget.season != api.season || widget.episode != api.episode) {
              throw StateError('Playback changed.');
            }
            final comment = await api.post(position, body);
            if (!mounted || widget.mediaId != api.mediaId ||
                widget.season != api.season || widget.episode != api.episode) return;
            _comments = [..._comments.where((c) => c.id != comment.id), comment]
              ..sort(_compare);
            _publishMarkers();
            _updateVisible(widget.player.state.position);
          },
        ),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final item in _visible)
              Padding(
                key: ValueKey(item.id),
                padding: const EdgeInsets.only(bottom: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${item.comment.name}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: item.comment.body),
                      ]),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TimedCommentComposer extends StatefulWidget {
  final Duration position;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Future<void> Function(String) onPost;

  const _TimedCommentComposer({
    required this.position,
    required this.enabled,
    required this.onToggle,
    required this.onPost,
  });

  @override
  State<_TimedCommentComposer> createState() => _TimedCommentComposerState();
}

class _TimedCommentComposerState extends State<_TimedCommentComposer> {
  final _text = TextEditingController();
  late bool _enabled = widget.enabled;
  bool _posting = false;
  String? _error;

  Future<void> _post() async {
    final body = _text.text.trim();
    if (_posting) return;
    if (body.isEmpty || body.length > 500) {
      setState(() => _error = 'Enter a comment of 1–500 characters.');
      return;
    }
    setState(() { _posting = true; _error = null; });
    try {
      await widget.onPost(body);
      if (mounted) closePlayerPanel(context);
    } catch (_) {
      if (mounted) setState(() {
        _posting = false;
        _error = 'Could not post the comment. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 14,
    children: [
      Row(children: [
        const Expanded(child: Text('Show timed comments')),
        PetalSwitch(value: _enabled, onChanged: (enabled) {
          setState(() => _enabled = enabled);
          widget.onToggle(enabled);
        }),
      ]),
      PetalTextField(controller: _text, maxLines: 3, maxLength: 500,
        placeholder: const Text('React to this moment')),
      if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12)),
      PetalButton.primary(onPressed: _posting ? null : _post,
        child: Text(_posting ? 'Posting…' : 'Post comment')),
    ],
  );
}
