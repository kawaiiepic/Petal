import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:petal/models/tmdb/season_summary.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SeasonDropdown extends StatelessWidget {
  final TmdbShow? tvShow;
  final SeasonSummary? selectedSeason;
  final void Function(SeasonSummary) onSeasonChanged;

  const SeasonDropdown({
    super.key,
    required this.tvShow,
    required this.selectedSeason,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final seasons = tvShow?.seasons ?? const <SeasonSummary>[];
    final scheme = Theme.of(context).colorScheme;
    return glass.GlassButton.custom(
      useOwnLayer: true,
      style: glass.GlassButtonStyle.transparent,
      shape: const glass.LiquidRoundedRectangle(borderRadius: 14),
      enabled: seasons.isNotEmpty,
      onTap: () async {
        SeasonSummary? selected;
        await glass.showGlassActionSheet<void>(
          context: context,
          title: 'Select a season',
          actions: [
            for (final season in seasons)
              glass.GlassActionSheetAction(
                label: season.name,
                icon: season.seasonNumber == selectedSeason?.seasonNumber ? const Icon(ios.CupertinoIcons.check_mark) : null,
                onPressed: () => selected = season,
              ),
          ],
        );
        if (selected != null && context.mounted) onSeasonChanged(selected!);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(selectedSeason?.name ?? 'Select a season',
            style: TextStyle(color: scheme.foreground, fontSize: AppTypography.h3Size, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Icon(ios.CupertinoIcons.chevron_down, color: scheme.foreground, size: 14),
        ],
      ),
      ),
    );
  }
}
