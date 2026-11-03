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
  Widget build(BuildContext context) => Select<SeasonSummary>(
    itemBuilder: (context, item) =>
        Text(style: TextStyle(fontSize: AppTypography.bodySize), item.name),
    popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
    onChanged: (value) {
      if (value != null) onSeasonChanged(value);
    },
    value: selectedSeason,
    placeholder: const Text('Select a season'),
    popup: SelectPopup(
      items: SelectItemList(
        children: [
          for (final season in tvShow?.seasons ?? const <SeasonSummary>[])
            SelectItemButton(value: season, child: Text(season.name)),
        ],
      ),
    ).call,
  );
}
