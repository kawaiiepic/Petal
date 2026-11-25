import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/tmdb/media_platform.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class MediaPlatformBadge extends StatelessWidget {
  const MediaPlatformBadge({super.key, required this.platform});

  final MediaPlatform platform;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: Api.proxyImage(platform.logoUrl),
    memCacheWidth: 92,
    placeholder: (_, _) => const SizedBox.shrink(),
    errorWidget: (_, _, _) => const SizedBox.shrink(),
    imageBuilder: (context, image) => Tooltip(
      tooltip: (_) => Text(
        platform.isOriginalNetwork
            ? platform.label
            : '${platform.label}\nAvailability data: JustWatch',
      ),
      child: Semantics(
        image: true,
        label: platform.label,
        child: SizedBox.square(
          dimension: 21,
          child: Image(
            image: image,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}
