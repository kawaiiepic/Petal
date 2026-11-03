import 'dart:html' as html;
import 'dart:ui_web' as web;

import 'package:petal/widgets/back_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class TestVideoPage extends StatefulWidget {
  final String streamUrl;

  const TestVideoPage({super.key, required this.streamUrl});

  @override
  State<StatefulWidget> createState() => _TestVideoPageState();
}

class _TestVideoPageState extends State<TestVideoPage> {
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
        ..type = 'video/mp4';

      video.children.add(source);

      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Flutter Web Iframe'),
          leading: [BackButton()],
        ),
      ],
      child: const Center(
        child: SizedBox(
          width: 500,
          height: 500,
          child: HtmlElementView(viewType: 'iframeElement'),
        ),
      ),
    );
  }
}
