import 'package:go_router/go_router.dart';
import 'package:petal/api/social_api.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class TitleComments extends StatefulWidget {
  final String mediaType;
  final int tmdbId;

  const TitleComments({super.key, required this.mediaType, required this.tmdbId});

  @override
  State<TitleComments> createState() => _TitleCommentsState();
}

class _TitleCommentsState extends State<TitleComments> {
  final _controller = TextEditingController();
  List<TitleComment> _comments = const [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TitleComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaType != widget.mediaType || oldWidget.tmdbId != widget.tmdbId) {
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final comments = await SocialApi.comments(widget.mediaType, widget.tmdbId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await SocialApi.postComment(widget.mediaType, widget.tmdbId, text);
      _controller.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No comments yet'),
          )
        else
          for (final comment in _comments.take(20))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Button.ghost(
                alignment: Alignment.centerLeft,
                onPressed: () => context.push('/profile/${comment.profileId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(comment.body),
                  ],
                ),
              ),
            ),
        Row(
          children: [
            Expanded(
              child: TextField(controller: _controller, placeholder: const Text('Write a comment')),
            ),
            const SizedBox(width: 8),
            Button.primary(onPressed: _posting ? null : _post, child: const Text('Post')),
          ],
        ),
      ],
    );
  }
}
