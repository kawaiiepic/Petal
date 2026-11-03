import 'package:petal/api/stream_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/streams/stream_tile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class StreamsPage extends StatefulWidget {
  final int? showId;
  final int? movieId;
  final Episode? episode;
  final bool download;

  const StreamsPage({
    super.key,
    this.showId,
    this.movieId,
    this.episode,
    this.download = false,
  });

  @override
  State<StreamsPage> createState() => _StreamsPageState();
}

class _StreamsPageState extends State<StreamsPage> {
  late Future<List<StreamItem>> _streamsFuture;
  late bool isShow;
  late Future<List<dynamic>> _showData;
  late Future<TmdbMovie> movie;

  @override
  void initState() {
    super.initState();
    _streamsFuture = _loadStreams();
    isShow = widget.showId != null;
    if (isShow) {
      _showData = Future.wait([
        TMDB.tvShow(widget.showId!),
        TMDB.tvEpisode(
          widget.showId!,
          widget.episode!.seasonNumber,
          widget.episode!.episodeNumber,
        ),
      ]);
    } else {
      movie = TMDB.movie(widget.movieId!);
    }
  }

  Future<List<StreamItem>> _loadStreams() async {
    final mediaImdb = widget.showId != null
        ? (await TMDB.tvShow(widget.showId!)).imdbId
        : (await TMDB.movie(widget.movieId!)).imdbId;
    return StreamApi.fetchStreams(mediaImdb!, widget.episode);
  }

  @override
  Widget build(BuildContext context) {
    if (isShow) {
      return FutureBuilder(
        future: _showData,
        builder: (context, showSnapshot) {
          return Scaffold(
            headers: [
              AppBar(
                leading: [BackButton()],
                title: Text(
                  style: TextStyle(
                    fontSize: Device.screenType == ScreenType.desktop
                        ? 15.sp
                        : 18.sp,
                  ),
                  showSnapshot.hasData
                      ? "${(showSnapshot.data![0] as TmdbShow).name} ${(showSnapshot.data![1] as TmdbEpisode).seasonNumber}x${(showSnapshot.data![1] as TmdbEpisode).episodeNumber}"
                      : '',
                ),
              ),
            ],
            child: FutureBuilder<List<StreamItem>>(
              future: _streamsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final streams = snapshot.data!;
                if (streams.isEmpty) {
                  return Center(
                    child: Text(
                      style: TextStyle(
                        fontSize: Device.screenType == ScreenType.desktop
                            ? 10.sp
                            : 13.sp,
                      ),
                      'No streams found',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: streams.length,
                  itemBuilder: (context, index) {
                    final stream = streams[index];
                    return StreamTile(
                      stream: stream,
                      tmdbId: widget.showId!,
                      episode: widget.episode,
                      download: widget.download,
                      mediaTitle: showSnapshot.hasData
                          ? (showSnapshot.data![0] as TmdbShow).name
                          : null,
                      episodeTitle: showSnapshot.hasData
                          ? (showSnapshot.data![1] as TmdbEpisode).name
                          : null,
                      title: widget.episode == null
                          ? 'Episode'
                          : 'S${widget.episode!.seasonNumber}:E${widget.episode!.episodeNumber}',
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }
    return FutureBuilder(
      future: movie,
      builder: (context, movieSnapshot) {
        return Scaffold(
          headers: [
            AppBar(
              title: Text(
                style: TextStyle(
                  fontSize: Device.screenType == ScreenType.desktop
                      ? 15.sp
                      : 18.sp,
                ),
                movieSnapshot.hasData ? movieSnapshot.data!.title : '',
              ),
            ),
          ],
          child: FutureBuilder<List<StreamItem>>(
            future: _streamsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final streams = snapshot.data!;
              if (streams.isEmpty) {
                return Center(
                  child: Text(
                    style: TextStyle(
                      fontSize: Device.screenType == ScreenType.desktop
                          ? 10.sp
                          : 13.sp,
                    ),
                    'No streams found',
                  ),
                );
              }
              return ListView.builder(
                itemCount: streams.length,
                itemBuilder: (context, index) {
                  final stream = streams[index];
                  return StreamTile(
                    stream: stream,
                    tmdbId: widget.movieId!,
                    download: widget.download,
                    title: movieSnapshot.data?.title ?? stream.title,
                    mediaTitle: movieSnapshot.data?.title,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
