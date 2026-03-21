import 'dart:typed_data';

import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/pages/streams.dart';
import 'package:flutter/material.dart';

class MovieOverview extends StatelessWidget {
  final Movie item;

  const MovieOverview({super.key, required this.item});

  String _formatRuntime(int? minutes) {
    if (minutes == null) return '';
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final movie = item;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Movie banner/poster
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<Uint8List>(
                future: TMDB.backdrop(movie.ids.tmdb.toString()),
                builder: (context, snapshot) {
                  if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover, alignment: AlignmentGeometry.center,);
                  return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
                },
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(movie.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),

                // Metadata row
                Wrap(
                  spacing: 12,
                  children: [
                    if (movie.year != null) Text('${movie.year}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    if (movie.runtime != null)
                      Text(_formatRuntime(movie.runtime), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    if (movie.rating != null && movie.rating! > 0)
                      Text('★ ${movie.rating!.toStringAsFixed(1)}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ...?movie.genres?.take(3).map((g) => _Chip(g)),
                  ],
                ),
                const SizedBox(height: 16),

                // Play button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final catalogItem = await StreamApi.fetchCatalogItemById(movie.ids.imdb.toString(), "movie");
                      if (catalogItem != null && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StreamsPage(item: catalogItem, episode: null, traktShow: null)));
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Play', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 24),

                // Movie overview
                if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                  Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(movie.overview!, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 24),
                ],

                // Additional info (rating, certification, runtime)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [if (movie.certification != null) _Chip(movie.certification!), if (movie.runtime != null) _Chip('${movie.runtime}m')],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
