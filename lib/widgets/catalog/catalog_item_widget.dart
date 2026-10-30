import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogItemWidget extends StatelessWidget {
  final CatalogItem? catalogItem;
  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  Widget build(BuildContext context) {
    final poster = catalogItem?.poster ?? '';
    final posterUrl = poster.isEmpty || poster.contains('blossomvale.dev')
        ? poster
        : Api.proxyImage(poster);
    return MediaCard(
      imageUrl: posterUrl,
      label: catalogItem?.name,
      onTap: () {
        if (catalogItem != null)
          context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
      },
      contextItems: [
        MenuButton(
          leading: const Icon(LucideIcons.play),
          trailing: const MenuShortcut(
            activator: SingleActivator(LogicalKeyboardKey.enter),
          ),
          onPressed: (_) {
            if (catalogItem != null)
              context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
          },
          child: const Text('Play'),
        ),
        MenuButton(
          leading: const Icon(LucideIcons.server),
          trailing: const MenuShortcut(
            activator: SingleActivator(
              LogicalKeyboardKey.bracketLeft,
              control: true,
            ),
          ),
          onPressed: (_) {
            if (catalogItem != null)
              context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
          },
          child: const Text('Select Source'),
        ),
        const MenuDivider(),
        MenuButton(
          leading: const Icon(LucideIcons.info),
          onPressed: (_) {
            if (catalogItem != null)
              context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
          },
          child: const Text('More Info'),
        ),
        const MenuDivider(),
        MenuButton(
          leading: const Icon(LucideIcons.bookmark),
          onPressed: (_) async {
            if (catalogItem == null) return;
            final resolved = await _resolveLibraryTarget(catalogItem!);
            if (resolved == null) return;
            await UserLibrary.toggleWatchlist(
              resolved.$1,
              resolved.$2,
              name: catalogItem!.name,
            );
          },
          child: const Text('Watchlist'),
        ),
        MenuButton(
          leading: const Icon(LucideIcons.check),
          onPressed: (_) async {
            if (catalogItem == null) return;
            final resolved = await _resolveLibraryTarget(catalogItem!);
            if (resolved == null) return;
            await UserLibrary.toggleWatched(resolved.$1, resolved.$2);
          },
          child: const Text('Watched'),
        ),
        MenuButton(
          leading: const Icon(LucideIcons.thumbsUp),
          onPressed: (_) async {
            if (catalogItem == null) return;
            final resolved = await _resolveLibraryTarget(catalogItem!);
            if (resolved == null) return;
            await UserLibrary.cycleRating(resolved.$1, resolved.$2);
          },
          child: const Text('Rate'),
        ),
      ],
    );
  }
}

Future<(int, MediaType)?> _resolveLibraryTarget(CatalogItem item) async {
  final type = item.type == 'movie' ? MediaType.movie : MediaType.show;
  final parsed = int.tryParse(item.id);
  if (parsed != null && !item.id.startsWith('tt')) return (parsed, type);
  try {
    final result = await ApiCache.getTmdbSearch(item.id);
    final match = type == MediaType.movie
        ? result.movies.firstOrNull
        : result.tv.firstOrNull;
    if (match == null) return null;
    return (match.id, type);
  } catch (_) {
    return null;
  }
}
