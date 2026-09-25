import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/models/custom_model.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/stream.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';
import 'package:petal/api/external_player.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamsPage extends StatefulWidget {
  final int? showId;
  final int? movieId;
  final Episode? episode;
  final bool download;

  const StreamsPage({super.key, this.showId, this.movieId, this.episode, this.download = false});

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
      _showData = Future.wait([TMDB.tvShow(widget.showId!), TMDB.tvEpisode(widget.showId!, widget.episode!.seasonNumber, widget.episode!.episodeNumber)]);
    } else {
      movie = TMDB.movie(widget.movieId!);
    }
  }

  Future<List<StreamItem>> _loadStreams() async {
    final mediaImdb = widget.showId != null ? (await TMDB.tvShow(widget.showId!)).imdbId : (await TMDB.movie(widget.movieId!)).imdbId;
    return StreamApi.fetchStreams(mediaImdb!, widget.episode);
  }

  @override
  Widget build(BuildContext context) {
    if (isShow) {
      return FutureBuilder(
        future: _showData,
        builder: (context, snapshot) {
          return Scaffold(
            headers: [
              AppBar(
                leading: [BackButton()],
                title: Text(
                  style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 15.sp : 18.sp),
                  snapshot.hasData
                      ? "${(snapshot.data![0] as TmdbShow).name} ${(snapshot.data![1] as TmdbEpisode).seasonNumber}x${(snapshot.data![1] as TmdbEpisode).episodeNumber}"
                      : '',
                ),
              ),
            ],
            child: FutureBuilder<List<StreamItem>>(
              future: _streamsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final streams = snapshot.data!;
                if (streams.isEmpty) {
                  return Center(child: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp), 'No streams found'));
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
                      title: widget.episode == null ? 'Episode' : 'S${widget.episode!.seasonNumber}:E${widget.episode!.episodeNumber}',
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
      builder: (context, snapshot) {
        return Scaffold(
          headers: [
            AppBar(
              title: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 15.sp : 18.sp), snapshot.hasData ? snapshot.data!.title : ''),
            ),
          ],
          child: FutureBuilder<List<StreamItem>>(
            future: _streamsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final streams = snapshot.data!;
              if (streams.isEmpty) {
                return Center(child: Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 10.sp : 13.sp), 'No streams found'));
              }
              return ListView.builder(
                itemCount: streams.length,
                itemBuilder: (context, index) {
                  final stream = streams[index];
                  return StreamTile(stream: stream, tmdbId: widget.movieId!, download: widget.download, title: stream.title);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class StreamTile extends StatelessWidget {
  final StreamItem stream;
  final int tmdbId;
  final Episode? episode;
  final bool download;
  final String title;

  const StreamTile({super.key, required this.stream, required this.tmdbId, this.episode, this.download = false, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return Button.card(
      leading: stream.external
          ? const Icon(RadixIcons.externalLink)
          : CachedNetworkImage(
              imageUrl: stream.addon.manifest?['logo'],
              imageBuilder: (context, imageProvider) => Avatar(initials: '', provider: imageProvider, backgroundColor: Colors.transparent),
              progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
            ),
      child: Column(
        children: [
          Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 14.sp), stream.name),
          Text(style: TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 11.sp : 13.sp), stream.title),
        ],
      ),
      onPressed: () async {
        if (download) {
          try {
            await DownloadManager.enqueueStream(
              stream: stream,
              tmdbId: tmdbId,
              title: title.isEmpty ? stream.title : title,
              season: episode?.seasonNumber,
              episode: episode?.episodeNumber,
            );
            if (context.mounted) context.push('/downloads');
          } catch (_) {
            if (context.mounted) {
              showToast(context: context, builder: (context, overlay) => const Text('This source cannot be saved on device.'));
            }
          }
          return;
        }
        if (stream.external) {
          launchUrl(Uri.parse(stream.url));
          return;
        }
        if (await ExternalPlayer.open(stream.url)) return;
        if (!context.mounted) return;
        if (episode != null) {
          context.pushReplacement('/player?media=$tmdbId&s=${episode?.seasonNumber}&e=${episode?.episodeNumber}', extra: stream);
        } else {
          context.pushReplacement('/player?media=$tmdbId', extra: stream);
        }
      },
    );
  }
}
