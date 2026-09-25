import 'package:go_router/go_router.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CommentsPage extends StatefulWidget {
  final String mediaType;
  final int tmdbId;
  final String title;

  const CommentsPage({super.key, required this.mediaType, required this.tmdbId, required this.title});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await SocialApi.comments(widget.mediaType, widget.tmdbId);
      if (mounted) setState(() {
        _comments = comments;
        _loading = false;
      });
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
    return Scaffold(
      headers: [
        AppBar(leading: const [BackButton()], title: Text(widget.title)),
      ],
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Padding(
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
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller, placeholder: const Text('Write a comment')),
                ),
                const SizedBox(width: 8),
                Button.primary(onPressed: _posting ? null : _post, child: const Text('Post')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
