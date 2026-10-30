import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petal/api/api.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// TMDB's transparent title artwork. Missing artwork leaves the image untouched.
class MediaTitleLogo extends StatefulWidget {
  final String url;
  const MediaTitleLogo({super.key, required this.url});

  @override
  State<MediaTitleLogo> createState() => _MediaTitleLogoState();
}

class _MediaTitleLogoState extends State<MediaTitleLogo> {
  late Future<Uint8List>? _svg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MediaTitleLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  void _load() {
    _svg = Uri.parse(widget.url).path.toLowerCase().endsWith('.svg')
        ? DefaultCacheManager()
              .getSingleFile(Api.proxyImage(widget.url))
              .then((file) => file.readAsBytes())
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_svg != null) {
      return FutureBuilder<Uint8List>(
        future: _svg,
        builder: (context, snapshot) => snapshot.hasData
            ? SvgPicture.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
              )
            : const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: Api.proxyImage(widget.url),
      memCacheWidth: 660,
      fit: BoxFit.contain,
      alignment: Alignment.topLeft,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
