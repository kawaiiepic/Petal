import 'package:flutter/cupertino.dart' show CupertinoSearchTextField;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _textController = TextEditingController();

  void _openResults() {
    final q = _textController.text.trim();
    if (q.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.push('/search?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
      final scheme = Theme.of(context).colorScheme;
      return CupertinoSearchTextField(
        controller: _textController,
        placeholder: 'Search shows and movies',
        backgroundColor: scheme.muted,
        itemColor: scheme.mutedForeground,
        style: TextStyle(color: scheme.foreground),
        onSubmitted: (_) => _openResults(),
      );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
