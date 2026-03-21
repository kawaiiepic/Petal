import 'dart:async';

import 'package:blssmpetal/models/stream.dart';
import 'package:blssmpetal/api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class StreamPlayer extends StatefulWidget {
  final StreamItem stream;
  const StreamPlayer({super.key, required this.stream});

  @override
  State<StatefulWidget> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  late final player = Player();
  late final controller = VideoController(player);
  String? _viewId;
  html.VideoElement? _videoElement;
  final isIOS = true;

  @override
  void initState() {
    super.initState();

    // In initState, register the view

    if (kIsWeb && isIOS) {
      // Register the factory immediately with a placeholder
      final viewId = 'video-${widget.stream.url.hashCode}';
      late html.VideoElement videoElement;
      videoElement = html.VideoElement()
        ..controls = true
        ..autoplay = true
        ..style.width = '100%'
        ..style.height = '100%';

      ui.platformViewRegistry.registerViewFactory(viewId, (_) => videoElement);

      // Store both so we can set src later
      _viewId = viewId;
      _videoElement = videoElement;
    }

     _startStream(widget.stream.url);
  }

  Future<void> _startStream(String url) async {
    print("Start stream ${kIsWeb}");
    if (kIsWeb) {
      try {
        final uri = Uri.parse("${Api.ServerUrl}/transcode?url=${Uri.encodeComponent(widget.stream.url)}");
         print("Fetching: $uri");

        final response = await http.get(uri);
         print("Response: ${response.statusCode} ${response.body}");

        print("Trrying to transcode");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final streamUrl = Api.ServerUrl + data["streamUrl"];

          print("Using HLS stream: $streamUrl");
          print(data);

          await Future.delayed(Duration(seconds: 5));

          if (isIOS) {
            _videoElement!.src = streamUrl;
            setState(() {}); // trigger rebuild, _viewId already set
          } else {
            player.open(Media(streamUrl));
          }
        } else {
          throw Exception("Transcode request failed");
        }
      } catch (e) {
        print("Transcode error: $e");

        // fallback to direct stream
        player.open(Media(widget.stream.url));
      }
    } else {
      print('');
      player.open(Media(url));
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        // Use [Video] widget to display video output.
        child: (kIsWeb && _viewId != null) ? HtmlElementView(viewType: _viewId!) : Video(controller: controller),
      ),
    );
  }
}
