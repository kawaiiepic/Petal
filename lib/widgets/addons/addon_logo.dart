import 'package:cached_network_image/cached_network_image.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class AddonLogo extends StatelessWidget {
  final String? logo;

  const AddonLogo({this.logo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CachedNetworkImage(
        imageUrl: logo ?? '',
        imageBuilder: (context, imageProvider) => Avatar(
          initials: 'A',
          provider: imageProvider,
          backgroundColor: Colors.transparent,
        ),
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.gray,
          ),
          child: const Icon(LucideIcons.puzzle),
        ),
      ),
    );
  }
}
