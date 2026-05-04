import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/models/custom_model.dart';

import 'package:petal/models/stream.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamsPage extends StatefulWidget {
  final int? showId;
  final int? movieId;
  final Episode? episode;

  const StreamsPage({super.key, this.showId, this.movieId, this.episode});

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
            appBar: AppBar(title: Text(snapshot.hasData ? (snapshot.data![0] as TmdbShow).name : 'Example Title')),
            body: FutureBuilder<List<StreamItem>>(
              future: _streamsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final streams = snapshot.data!;
                if (streams.isEmpty) {
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('No \'stream\' capable Addons'));
                  } else {
                    return const Center(child: Text('No streams found'));
                  }
                }

                return ListView.builder(
                  itemCount: streams.length,
                  itemBuilder: (context, index) {
                    final stream = streams[index];
                    return StreamTile(stream: stream, tmdbId: widget.showId!, episode: widget.episode);
                  },
                );
              },
            ),
          );
        },
      );
    } else {
      return FutureBuilder(
        future: movie,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(title: Text(snapshot.hasData ? snapshot.data!.title : 'Example Title')),
            body: FutureBuilder<List<StreamItem>>(
              future: _streamsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final streams = snapshot.data!;
                if (streams.isEmpty) {
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('No \'stream\' capable Addons'));
                  } else {
                    return const Center(child: Text('No streams found'));
                  }
                }

                return ListView.builder(
                  itemCount: streams.length,
                  itemBuilder: (context, index) {
                    final stream = streams[index];
                    return StreamTile(stream: stream, tmdbId: widget.movieId!);
                  },
                );
              },
            ),
          );
        },
      );
    }
  }
}

class StreamTile extends StatelessWidget {
  final StreamItem stream;
  final int tmdbId;
  final Episode? episode;

  const StreamTile({super.key, required this.stream, required this.tmdbId, this.episode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: stream.external ? const Icon(Icons.play_circle) : const Icon(Icons.play_circle_outline),
      title: Text(stream.name),
      subtitle: Text(stream.title),
      trailing: Text(stream.addon.name),
      onTap: () {
        if (stream.external) {
          launchUrl(Uri.parse(stream.url));
        }
        if (kIsWeb) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Playback not supported"),
                content: SelectableText("This stream can't be played in the built-in player. Open it externally.\n\n${stream.url}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      if (episode != null) {
                        context.pushReplacement('/player?show=$tmdbId&s=${episode?.seasonNumber}&e=${episode?.episodeNumber}&url=${stream.url}');
                      }

                      // Navigator.pop(context);
                    },
                    child: const Text("Open Stream"),
                  ),
                ],
              );
            },
          );
        } else {
          if (episode != null) {
            context.pushReplacement('/player?show=$tmdbId&s=${episode?.seasonNumber}&e=${episode?.episodeNumber}', extra: stream);
          }
        }
      },
    );
  }
}
