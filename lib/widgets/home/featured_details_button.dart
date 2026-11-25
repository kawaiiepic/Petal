import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/models/catalog_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FeaturedDetailsButton extends StatelessWidget {
  const FeaturedDetailsButton({super.key, required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) => glass.GlassButton.custom(
    label: 'View details',
    height: 44,
    shape: const glass.LiquidRoundedSuperellipse(borderRadius: 22),
    surfaceStyle: glass.GlassSurfaceStyle.solid,
    color: const Color(0xFFF7F7F8),
    onTap: () {
      final type = item.type == 'movie' ? 'movie' : 'series';
      final key = int.tryParse(item.id) == null ? 'imdb' : 'tmdb';
      context.push('/$type?$key=${Uri.encodeQueryComponent(item.id)}');
    },
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 7,
        children: [
          Text(
            'View details',
            style: TextStyle(
              color: Color(0xFF17171A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 15, color: Color(0xFF17171A)),
        ],
      ),
    ),
  );
}
