import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class Collection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Collection();
}

class _Collection extends State<Collection> {
  int index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    headers: [
      AppBar(
        leadingGap: 30,
        leading: [
          BackButton(),
          Text('Collection'),
          Tabs(
            index: index,
            children: const [
              TabItem(child: Text('Tab 1')),
              TabItem(child: Text('Tab 2')),
              TabItem(child: Text('Tab 3')),
            ],
            onChanged: (int value) {
              // Keep header and body in sync by updating state.
              setState(() {
                index = value;
              });
            },
          ),
          Select<String>(
            itemBuilder: (context, item) {
              return Text(item);
            },
            popup: const SelectPopup(),
          ),
        ],
      ),
    ],
    child: WatchList(),
  );
}

class WatchList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.watchHistory,
      builder: (context, history, child) {
        // Collapse multiple episode entries for the same show/movie
        // down to just the most recently watched one.
        final Map<int, dynamic> latestByTmdbId = {};
        for (final item in history) {
          final existing = latestByTmdbId[item.tmdbId];
          if (existing == null || item.updatedAt.compareTo(existing.updatedAt) > 0) {
            latestByTmdbId[item.tmdbId] = item;
          }
        }
        final deduped = latestByTmdbId.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return GridView.builder(
          itemCount: deduped.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 3 / 4, mainAxisSpacing: 16, crossAxisSpacing: 16),
          itemBuilder: (context, index) {
            final WatchHistoryItem item = deduped[index];
            if (item.mediaType == "episode")
              return FutureBuilder(
                future: TMDB.tvShow(item.tmdbId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return HoverableItem(
                      image: CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/original' + snapshot.data!.posterPath!, fit: BoxFit.cover),
                    );
                  } else {
                    return Text('Loading');
                  }
                },
              );
            else {
              return FutureBuilder(
                future: TMDB.movie(item.tmdbId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return HoverableItem(
                      image: CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/original' + snapshot.data!.posterPath!, fit: BoxFit.cover),
                    );
                  } else {
                    return Text('Loading');
                  }
                },
              );
            }
          },
        );
      },
    );
  }
}
