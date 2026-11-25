import 'package:petal/pages/player/overlay/player_glass_panel.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_season.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/pages/player/playback_scope.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EpisodeDrawer extends StatelessWidget {
  final Future<(TmdbShow, TmdbEpisode)> showData;
  final int tmdbId;
  const EpisodeDrawer({super.key, required this.showData, required this.tmdbId});

  Future<void> _open(BuildContext context) async {
    final playback = PlaybackScope.maybeOf(context);
    final chosen = await showPlayerGlassPanel<Episode>(context, title: 'Episodes',
      maxWidth: 560, builder: (_) => _EpisodeList(showData: showData, tmdbId: tmdbId));
    if (context.mounted && chosen != null && playback != null) {
      await playback.playEpisode(chosen);
    }
  }

  @override
  Widget build(BuildContext context) => ControlButton(
    onTap: () => _open(context),
    icon: Icon(LucideIcons.listOrdered, size: AppTypography.normalIconSize),
  );
}

class _EpisodeList extends StatefulWidget {
  final Future<(TmdbShow, TmdbEpisode)> showData;
  final int tmdbId;
  const _EpisodeList({required this.showData, required this.tmdbId});
  @override
  State<_EpisodeList> createState() => _EpisodeListState();
}

class _EpisodeListState extends State<_EpisodeList> {
  int? _season;
  final _seasons = <int, Future<TmdbSeason>>{};

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: widget.showData,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('Could not load episodes.');
      if (!snapshot.hasData) return const Center(child: PetalActivityIndicator());
      final (show, current) = snapshot.data!;
      final selected = _season ?? current.seasonNumber;
      final label = show.seasons.where((s) => s.seasonNumber == selected).firstOrNull?.releaseLabel ?? 'Season $selected';
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
        PetalButton.secondary(
          onPressed: () async {
            int? choice;
            await showPlayerMenu(context, title: 'Select a season',
              actions: [
                for (final season in show.seasons)
                  PlayerMenuAction(label: season.releaseLabel,
                    icon: selected == season.seasonNumber ? const Icon(LucideIcons.check) : null,
                    onPressed: () => choice = season.seasonNumber),
              ]);
            if (mounted && choice != null) setState(() => _season = choice);
          },
          trailing: const Icon(LucideIcons.chevronDown, size: 16), child: Text(label)),
        FutureBuilder(
          future: _seasons.putIfAbsent(selected, () => TMDB.tvSeason(widget.tmdbId, selected)),
          builder: (context, episodes) {
            if (episodes.hasError) return PetalButton.secondary(
              onPressed: () => setState(() => _seasons.remove(selected)), child: const Text('Retry'));
            if (!episodes.hasData) return const Center(child: PetalActivityIndicator());
            return Column(spacing: 8, children: [
              for (final ep in episodes.data!.episodes)
                PetalButton.card(
                  onPressed: () => closePlayerPanel(context, Episode(
                    seasonNumber: ep.seasonNumber, episodeNumber: ep.episodeNumber)),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 92, height: 52,
                        child: MediaArtwork(imageUrl: ep.stillUrl))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${ep.episodeNumber}. ${ep.name}', maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(ep.overview, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.mutedForeground)),
                    ])),
                    if (ep.seasonNumber == current.seasonNumber && ep.episodeNumber == current.episodeNumber)
                      const Padding(padding: EdgeInsets.only(left: 8), child: Icon(LucideIcons.play, size: 16)),
                  ]),
                ),
            ]);
          },
        ),
      ]);
    },
  );
}
