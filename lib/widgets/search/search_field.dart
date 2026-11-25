import 'dart:async';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.placeholder = 'Search shows and movies',
    this.initialQuery = '',
    this.replaceResults = false,
    this.onQueryChanged,
  });

  final String placeholder;
  final String initialQuery;
  final bool replaceResults;
  final ValueChanged<String>? onQueryChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _textController = TextEditingController(text: widget.initialQuery);

  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _textController.addListener(_changed);
  }

  void _changed() {
    if (widget.onQueryChanged == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) widget.onQueryChanged?.call(_textController.text.trim());
    });
  }

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        _textController.text.trim() != widget.initialQuery) {
      _textController.text = widget.initialQuery;
      _debounce?.cancel();
    }
  }

  void _openResults() {
    _debounce?.cancel();
    final q = _textController.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.onQueryChanged != null) {
      widget.onQueryChanged!(q);
      return;
    }
    if (q.isEmpty) return;
    context.go(Uri(path: '/search', queryParameters: {'q': q}).toString());
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
    _debounce?.cancel();
    _textController.removeListener(_changed);
    _textController.dispose();
    super.dispose();
  }
}
