import 'dart:async';

import 'package:petal/api/api_cache.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/router/router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _textController = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  List<Addon>? _addons;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    ApiCache.getAddons().then((addons) {
      if (!mounted) return;
      _addons = addons;
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _suggestions = []);
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
    try {
      final raw = await StreamApi.searchCatalogItems(query, addons);
      if (!mounted || id != _requestId) return;

      final seen = <String>{};
      final names = <String>[];
      for (final item in raw) {
        if (item.type != 'movie' && item.type != 'series') continue;
        if (item.name.trim().isEmpty) continue;
        if (!seen.add(item.name.toLowerCase())) continue;
        names.add(item.name);
        if (names.length >= 8) break;
      }

      setState(() => _suggestions = names);
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _suggestions = []);
    }
  }

  void _openResults([String? query]) {
    final q = (query ?? _textController.text).trim();
    if (q.isEmpty) return;
    AppRouter.appRouter.push('/search?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    return AutoComplete(
      suggestions: _suggestions,
      mode: AutoCompleteMode.replaceAll,
      popoverConstraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
      overlayConfiguration: const PopoverConfiguration(
        alignment: AlignmentDirectional.topStart,
        anchorAlignment: AlignmentDirectional.bottomStart,
        widthConstraint: PopoverConstraint.anchorFixedSize,
      ),
      completer: (suggestion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openResults(suggestion);
        });
        return suggestion;
      },
      child: TextField(
        controller: _textController,
        placeholder: const Text('Search TV Shows, Movies & more...'),
        onChanged: _onChanged,
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
    _textController.dispose();
    super.dispose();
  }
}
