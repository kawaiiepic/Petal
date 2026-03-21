import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:ui_web' as web;

class TestVideo extends StatefulWidget {
  final String streamUrl;

  const TestVideo({super.key, required this.streamUrl});

  @override
  State<StatefulWidget> createState() => _TestVideo();
}

class _TestVideo extends State<TestVideo> {
  @override
  void initState() {
    super.initState();
    web.platformViewRegistry.registerViewFactory('videoElement', (int viewId) {
      final video = html.VideoElement()
        ..width = 500
        ..height = 500
        ..controls = true;

      final source = html.SourceElement()
        ..src = widget.streamUrl
        ..type = 'video/mp4'; // 👈 set MIME type here

      video.children.add(source);

      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Web Iframe")),
      body: Center(
        child: SizedBox(
          // Use SizedBox or Container to define the dimensions
          width: 500,
          height: 500,
          child: HtmlElementView(viewType: 'iframeElement'),
        ),
      ),
    );
  }
}
