import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/episode.dart';
import 'package:blssmpetal/models/trailer.dart';
import 'package:blssmpetal/pages/streams.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OverviewPage extends StatelessWidget {
  final CatalogItem item;

  const OverviewPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── HEADER ───────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(item.name),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item.background, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENT ──────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ▶ PLAY BUTTON
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StreamsPage(item: item, episode: Episode(season: 0, episode: 1, title: '', overview: '', thumbnail: ''),))),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),

                const SizedBox(height: 16),

                // METADATA
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoChip(item.year.toString()),
                    _InfoChip(item.runtime),
                    _InfoChip("IMDb ${item.imdbRating}"),
                    // if (item.country.isNotEmpty) _InfoChip(item.country),
                  ],
                ),

                const SizedBox(height: 16),

                // OVERVIEW
                _SectionTitle("Overview"),
                Text(item.description),

                // GENRES
                if (item.genres.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Genres"), _ChipWrap(item.genres)],

                // CAST
                if (item.cast.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Cast"), _ChipWrap(item.cast)],

                // DIRECTORS
                if (item.directors.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Director"), _ChipWrap(item.directors)],

                // WRITERS
                if (item.writers.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Writers"), _ChipWrap(item.writers)],

                // AWARDS
                if (item.awards.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Awards"), Text(item.awards)],

                // SEASONS
                if (item.type == 'series' && item.seasons.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Episodes"), _SeasonList(item)],

                // TRAILERS
                if (item.trailers.isNotEmpty) ...[const SizedBox(height: 24), _SectionTitle("Trailers"), _TrailerRow(item.trailers)],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonList extends StatelessWidget {
  final CatalogItem item;

  const _SeasonList(this.item);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: item.seasons.map((season) {
        return ExpansionTile(
          title: Text("Season ${season.number}"),
          children: season.episodes.map((ep) {
            return ListTile(
              leading: ep.thumbnail.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: ep.thumbnail,
                        width: 100,
                        height: 56,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, downloadProgress) =>
                            Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                      // child: Image.network(
                      //   ep.thumbnail,
                      //   width: 100,
                      //   height: 56,
                      //   fit: BoxFit.cover,
                      //   errorBuilder: (context, error, stackTrace) {
                      //     print("Image failed to load!!");
                      //     return Text("Error");
                      //   },
                      // ),
                    )
                  : null,
              title: Text("E${ep.episode} · ${ep.title}"),
              subtitle: Text(ep.overview, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StreamsPage(
                      item: item,
                      episode: ep, // you’ll want this param
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;

  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(text), backgroundColor: Theme.of(context).colorScheme.surfaceVariant);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> items;

  const _ChipWrap(this.items);

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: items.map((e) => Chip(label: Text(e))).toList());
  }
}

class _TrailerRow extends StatelessWidget {
  final List<Trailer> trailers;

  const _TrailerRow(this.trailers);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trailers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final t = trailers[index];
          return GestureDetector(
            // onTap: () => {Navigator.push(context, MaterialPageRoute(builder: (_) => TrailerPlayer(videoId: t.ytId)))},
            onTap: () async {
              var _url = Uri.parse('https://www.youtube.com/watch?v=${t.ytId}');
              if (!await launchUrl(_url)) {
                throw Exception('Could not launch $_url');
              }
              print("Youtube -" + t.ytId);
              // open YouTube / player
            },
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network("https://img.youtube.com/vi/${t.ytId}/0.jpg", width: 160, height: 90, fit: BoxFit.cover),
                ),
                const SizedBox(height: 4),
                SizedBox(width: 160, child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        },
      ),
    );
  }
}
