import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/pages/scrollable_widget.dart';
import 'package:flutter/material.dart';

class TraktNextUp extends StatefulWidget {
  const TraktNextUp({super.key});

  @override
  State<StatefulWidget> createState() => _TraktNextUp();
}

class _TraktNextUp extends State<TraktNextUp> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 18);
    return FutureBuilder(
      future: ApiCache.getTraktWatched(),
      builder: (context, watchedSnapshot) {
        switch (watchedSnapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.done:
            {
              final traktWatched = watchedSnapshot.data!;

              return Column(
                spacing: 8,
                children: [
                  Text('Next Up', style: style),
                  SizedBox(
                    height: 250,
                    child: ScrollableWidget(
                      controller: _controller,
                      child: ListView.builder(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        itemCount: traktWatched.length,
                        itemBuilder: (context, index) {
                          final watchedItem = traktWatched[index];
                          return TraktNextUpItem(show: watchedItem);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
          case _:
            return SizedBox();
        }
      },
    );
  }
}

class TraktNextUpItem extends StatefulWidget {
  final TraktWatchedShowWithProgress show;

  const TraktNextUpItem({super.key, required this.show});

  @override
  State<StatefulWidget> createState() => _TraktNextUpItem();
}

class _TraktNextUpItem extends State<TraktNextUpItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ApiCache.getTmdbStill(widget.show.watchedShow!.show.ids.tmdb.toString(), widget.show.showProgress.nextEpisode!),
    builder: (context, tmdbPosterSnapshot) {
      switch (tmdbPosterSnapshot.connectionState) {
        case ConnectionState.active:
        case ConnectionState.done:
          {
            if (tmdbPosterSnapshot.hasError) {
              return const SizedBox();
            }
            return MouseRegion(
              onEnter: (event) => setState(() {
                _isHovering = true;
              }),
              onExit: (event) => setState(() {
                _isHovering = false;
              }),
              child: GestureDetector(
                // onTap: () async {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => EpisodeOverview(item: widget.show, selectedEpisode: widget.show.showProgress.nextEpisode),
                //     ),
                //   );
                // },

                child: Column(
                  spacing: 8,
                  children: [
                    Container(
                      color: Colors.transparent,
                      width: 400,
                      height: 190,
                      child: Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _isHovering ? Colors.white : Colors.transparent),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(8),
                            child: AnimatedScale(
                              scale: _isHovering ? 1.1 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: Image.memory(tmdbPosterSnapshot.data!, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Text(
                      "${widget.show.showProgress.nextEpisode!.season}x${widget.show.showProgress.nextEpisode!.number} ${widget.show.watchedShow!.show.title}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Text(widget.show.showProgress.nextEpisode!.title!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }
        case _:
          return const SizedBox();
      }
    },
  );
}
