import 'package:petal/models/tmdb/season_summary.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SeasonDropdown extends StatefulWidget {
  final TmdbShow? tvShow;
  final SeasonSummary? selectedSeason;
  final void Function(SeasonSummary) onSeasonChanged;
  const SeasonDropdown({
    required this.tvShow,
    required this.selectedSeason,
    required this.onSeasonChanged,
  });
  @override
  State<SeasonDropdown> createState() => _SeasonDropdownState();
}

class _SeasonDropdownState extends State<SeasonDropdown> {
  SeasonSummary? _selectedSeason;
  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.selectedSeason;
  }

  @override
  Widget build(BuildContext context) {
    return Select<SeasonSummary>(
      itemBuilder: (context, item) =>
          Text(style: TextStyle(fontSize: AppTypography.bodySize), item.name),
      popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
      onChanged: (value) {
        setState(() => _selectedSeason = value);
        widget.onSeasonChanged(value!);
      },
      value: _selectedSeason,
      placeholder: const Text('Select a season'),
      popup: SelectPopup(
        items: SelectItemList(
          children: widget.tvShow != null
              ? widget.tvShow!.seasons
                    .map((s) => SelectItemButton(value: s, child: Text(s.name)))
                    .toList()
              : List.generate(
                  5,
                  (index) => SelectItemButton(
                    value: 'Queer',
                    child: Text('Example Season'),
                  ),
                ),
        ),
      ).call,
    );
  }
}
