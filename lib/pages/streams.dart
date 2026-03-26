// import 'package:blssmpetal/api/api.dart';
// import 'package:blssmpetal/api/api_cache.dart';
// import 'package:blssmpetal/api/stream_helper.dart';
// import 'package:blssmpetal/api/trakt/models.dart';
// import 'package:blssmpetal/models/catalog_item.dart';

// import 'package:blssmpetal/models/stream.dart';
// import 'package:blssmpetal/models/stremio/stremio_episode.dart';
// import 'package:blssmpetal/pages/player/player_old.dart';
// import 'package:blssmpetal/pages/test_video.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class StreamsPage extends StatefulWidget {
//   final CatalogItem item;
//   final StremioEpisode? episode;
//   final TraktShow? traktShow;

//   const StreamsPage({super.key, required this.item, this.episode, this.traktShow});

//   @override
//   State<StreamsPage> createState() => _StreamsPageState();
// }

// class _StreamsPageState extends State<StreamsPage> {
//   late Future<List<StreamItem>> _streamsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _streamsFuture = _loadStreams();
//   }

//   Future<List<StreamItem>> _loadStreams() async {
//     final addons = await ApiCache.getAddons();
//     return StreamApi.fetchStreams(widget.item, addons, episode: widget.episode);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.item.name)),
//       body: FutureBuilder<List<StreamItem>>(
//         future: _streamsFuture,
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final streams = snapshot.data!;
//           if (streams.isEmpty) {
//             if (snapshot.data!.isEmpty) {
//               return const Center(child: Text('No \'stream\' capable Addons'));
//             } else {
//               return const Center(child: Text('No streams found'));
//             }
//           }

//           return ListView.builder(
//             itemCount: streams.length,
//             itemBuilder: (context, index) {
//               final stream = streams[index];
//               return StreamTile(stream: stream, item: widget.item, episode: widget.episode, traktShow: widget.traktShow);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class StreamTile extends StatelessWidget {
//   final StreamItem stream;
//   final CatalogItem item;
//   final StremioEpisode? episode;
//   final TraktShow? traktShow;

//   const StreamTile({super.key, required this.stream, required this.item, this.episode, this.traktShow});

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: stream.external ? const Icon(Icons.play_circle) : const Icon(Icons.play_circle_outline),
//       title: Text(stream.name),
//       subtitle: Text(stream.title),
//       trailing: Text(stream.addon.name),
//       onTap: () {
//         if (stream.external) {
//           launchUrl(Uri.parse(stream.url));
//         }
//         if (kIsWeb) {
//           showDialog(
//             context: context,
//             builder: (context) {
//               return AlertDialog(
//                 title: const Text("Playback not supported"),
//                 content: SelectableText("This stream can't be played in the built-in player. Open it externally.\n\n${stream.url}"),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Text("Cancel"),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(builder: (_) => StreamPlayer(stream: stream)));
//                       // Navigator.pop(context);
//                     },
//                     child: const Text("Open Stream"),
//                   ),
//                 ],
//               );
//             },
//           );
//         } else {
//           Navigator.push(context, MaterialPageRoute(builder: (_) => StreamPlayer(stream: stream)));
//         }
//       },
//     );
//   }
// }
