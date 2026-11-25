import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.placeholder = 'Search shows and movies',
    this.initialQuery = '',
    this.replaceResults = false,
  });

  final String placeholder;
  final String initialQuery;
  final bool replaceResults;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _textController = TextEditingController(text: widget.initialQuery);

  void _openResults() {
    final q = _textController.text.trim();
    if (q.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (q == widget.initialQuery) return;
    final route = '/search?q=${Uri.encodeQueryComponent(q)}';
    if (widget.replaceResults) {
      context.replace(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return glass.GlassSearchBar(
      useOwnLayer: true,
      controller: _textController,
      placeholder: widget.placeholder,
      searchIconColor: scheme.mutedForeground,
      clearIconColor: scheme.mutedForeground,
      textStyle: TextStyle(color: scheme.foreground),
      onSubmitted: (_) => _openResults(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
