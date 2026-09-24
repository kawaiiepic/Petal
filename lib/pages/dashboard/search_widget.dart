import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _textController = TextEditingController();

  void _openResults() {
    final q = _textController.text.trim();
    if (q.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.push('/search?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      placeholder: const Text('Search TV Shows, Movies & more...'),
      onSubmitted: (_) => _openResults(),
      features: [
        const InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
        InputFeature.trailing(
          IconButton.ghost(
            icon: const Icon(LucideIcons.search),
            onPressed: _openResults,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
