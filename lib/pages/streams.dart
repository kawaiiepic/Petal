import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/stream.dart';
import 'package:blssmpetal/pages/player.dart';
import 'package:flutter/material.dart';

class StreamsPage extends StatefulWidget {
  final CatalogItem item;

  const StreamsPage({super.key, required this.item});

  @override
  State<StreamsPage> createState() => _StreamsPageState();
}

class _StreamsPageState extends State<StreamsPage> {
  late Future<List<StreamItem>> _streamsFuture;

  @override
  void initState() {
    super.initState();
    _streamsFuture = _loadStreams();
  }

  Future<List<StreamItem>> _loadStreams() async {
    final addons = await Api.addonsFuture;
    return StreamApi.fetchStreams(widget.item, addons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: FutureBuilder<List<StreamItem>>(
        future: _streamsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final streams = snapshot.data!;
          if (streams.isEmpty) {
            return const Center(child: Text('No streams found'));
          }

          return ListView.builder(
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              return StreamTile(stream: stream);
            },
          );
        },
      ),
    );
  }
}

class StreamTile extends StatelessWidget {
  final StreamItem stream;

  const StreamTile({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.play_circle),
      title: Text(stream.name),
      subtitle: Text(stream.title),
      trailing: Text(stream.addon.name),
      onTap: () {
        // later: open player / external app
        Navigator.push(context, MaterialPageRoute(builder: (_) => StreamPlayer(stream: stream)));
        debugPrint(stream.url);
      },
    );
  }
}
