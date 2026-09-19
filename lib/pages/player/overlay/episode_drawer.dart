import 'package:go_router/go_router.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class EpisodeDrawer extends StatefulWidget {
  final Future<(TmdbShow, TmdbEpisode)> showData;
  final int tmdbId;

  const EpisodeDrawer({super.key, required this.showData, required this.tmdbId});

  @override
  State<EpisodeDrawer> createState() => _EpisodeDrawerState();
}

class _EpisodeDrawerState extends State<EpisodeDrawer> {
  SeasonSummary? _selectedSeason;
  final Map<int, Future<TmdbSeason>> _loadedSeasons = {};

  @override
  void initState() {
    super.initState();
    initSeason();
  }

  Future<void> initSeason() async {
    final data = await widget.showData;
    _selectedSeason = data.$1.seasons.firstWhere((s) => s.seasonNumber == data.$2.seasonNumber);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayAnchor(
      anchor: #outerDrawerButton,
      child: ControlButton(
        onTap: () {
          showOverlay(
            context,
            DrawerConfiguration(anchor: LinkedAnchor(#outerDrawerButton), expands: true),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    FutureBuilder(
                      future: widget.showData,
                      builder: (context, snapshot) {
                        return DrawerOverlay(
                          child: OverlayAnchor(
                            anchor: #select,
                            child: Select<SeasonSummary>(
                              overlayConfiguration: PopoverConfiguration(alignment: AlignmentGeometry.center, anchor: LinkedAnchor(#select)),
                              itemBuilder: (context, item) => Text(style: Misc.normalTextStyle, _selectedSeason?.name ?? ''),
                              onChanged: (value) {
                                setState(() => _selectedSeason = value);
                              },
                              value: _selectedSeason,
                              placeholder: Text(style: Misc.normalTextStyle, 'Select a season'),
                              popup: SelectPopup(
                                items: SelectItemList(
                                  children: snapshot.hasData
                                      ? snapshot.data!.$1.seasons
                                            .map(
                                              (s) => SelectItemButton(
                                                value: s,
                                                child: Text(style: Misc.normalTextStyle, s.name),
                                              ),
                                            )
                                            .toList()
                                      : [],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    FutureBuilder(
                      future: _loadedSeasons.putIfAbsent(
                        _selectedSeason?.seasonNumber ?? 0,
                        () => TMDB.tvSeason(widget.tmdbId, _selectedSeason?.seasonNumber ?? 0),
                      ),
                      builder: (context, snapshot) {
                        return snapshot.hasData
                            ? Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: snapshot.data!.episodes
                                      .map(
                                        (episode) => Padding(
                                          padding: EdgeInsetsGeometry.fromLTRB(0, 4, 0, 4),
                                          child: GhostButton(
                                            onPressed: () {
                                              context.pushReplacement('/player?media=${widget.tmdbId}&s=${episode.seasonNumber}&e=${episode.episodeNumber}');
                                            },
                                            child: Row(
                                              spacing: 12,
                                              children: [
                                                if (episode.stillPath != null)
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.network(
                                                      'https://image.tmdb.org/t/p/w300${episode.stillPath}',
                                                      width: 120,
                                                      height: 68,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    spacing: 8,
                                                    children: [
                                                      Text(style: Misc.normalTextStyle.copyWith(fontSize: 13.sp), '${episode.episodeNumber}. ${episode.name}'),
                                                      Text(
                                                        style: Misc.normalTextStyle.copyWith(fontSize: 13.sp),
                                                        episode.overview,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        icon: Icon(size: Misc.normalIconSize, LucideIcons.listOrdered),
      ),
    );
  }
}
