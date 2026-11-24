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
    return ios.CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: scheme.secondary,
      borderRadius: BorderRadius.circular(12),
      onPressed: seasons.isEmpty ? null : () async {
        final selected = await ios.showCupertinoModalPopup<SeasonSummary>(
          context: context,
          builder: (sheetContext) => ios.CupertinoActionSheet(
            title: const Text('Select a season'),
            actions: [
              for (final season in seasons)
                ios.CupertinoActionSheetAction(
                  isDefaultAction: season == selectedSeason,
                  onPressed: () => Navigator.of(sheetContext).pop(season),
                  child: Text(season.name),
                ),
            ],
            cancelButton: ios.CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Cancel'),
            ),
          ),
        );
        if (selected != null && context.mounted) onSeasonChanged(selected);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(selectedSeason?.name ?? 'Select a season',
            style: TextStyle(color: scheme.foreground, fontSize: AppTypography.bodySize))),
          const SizedBox(width: 8),
          Icon(ios.CupertinoIcons.chevron_down, color: scheme.foreground, size: 14),
        ],
      ),
    );
  }
}
