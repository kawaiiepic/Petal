import 'dart:async';

import 'package:petal/api/api_cache.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/router/router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  Timer? _hideTimer;
  int _requestId = 0;

  List<Addon>? _addons;
  List<CatalogItem> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ApiCache.getAddons().then((addons) {
      if (!mounted) return;
      _addons = addons;
    });
    _textController.addListener(_onQueryChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _hideTimer?.cancel();
        if (_suggestions.isNotEmpty) _showSuggestions();
      } else {
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(milliseconds: 180), _hideSuggestions);
      }
    });
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = _textController.text.trim();
    if (query.length < 2) {
      _hideSuggestions();
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 280), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final addons = _addons;
    if (addons == null) return;

    final id = ++_requestId;
    setState(() => _loading = true);
    _showSuggestions();

    try {
      final raw = await StreamApi.searchCatalogItems(query, addons);
      if (!mounted || id != _requestId) return;

      final seen = <String>{};
      final items = <CatalogItem>[];
      for (final item in raw) {
        if (item.type != 'movie' && item.type != 'series') continue;
        if (!seen.add('${item.type}:${item.id}')) continue;
        items.add(item);
        if (items.length >= 8) break;
      }

      setState(() {
        _suggestions = items;
        _loading = false;
      });
      _showSuggestions();
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _loading = false);
      _showSuggestions();
    }
  }

  void _showSuggestions() {
    _overlayEntry?.remove();
    if (_suggestions.isEmpty && !_loading) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 44),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 320, minWidth: 240),
              decoration: BoxDecoration(
                color: Theme.of(this.context).colorScheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(this.context).colorScheme.border),
              ),
              child: _loading && _suggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        return Button.ghost(
                          alignment: Alignment.centerLeft,
                          leading: Icon(item.type == 'movie' ? LucideIcons.ticket : LucideIcons.tv),
                          onPressed: () => _openResults(item.name),
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openResults([String? query]) {
    final q = (query ?? _textController.text).trim();
    if (q.isEmpty) return;
    _hideTimer?.cancel();
    _hideSuggestions();
    _focusNode.unfocus();
    AppRouter.appRouter.push('/search?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        placeholder: const Text('Search TV Shows, Movies & more...'),
        onSubmitted: (_) => _openResults(),
        features: [
          const InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
          InputFeature.trailing(
            IconButton.ghost(
              icon: const Icon(LucideIcons.search),
              onPressed: () => _openResults(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideTimer?.cancel();
    _hideSuggestions();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
