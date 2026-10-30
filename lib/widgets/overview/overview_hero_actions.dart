import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/widgets/overview/library_actions.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OverviewHeroActions extends StatelessWidget {
  final Widget play;
  final VoidCallback? onTrailer;
  final int? tmdbId;
  final MediaType mediaType;
  final TmdbShow? show;
  final String? title;

  const OverviewHeroActions({
    super.key,
    required this.play,
    required this.mediaType,
    this.onTrailer,
    this.tmdbId,
    this.show,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            play,
            if (onTrailer != null)
              Button(
                onPressed: onTrailer,
                style: const ButtonStyle.outline().withBorderRadius(
                  borderRadius: BorderRadius.circular(16),
                  hoverBorderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.video, size: 18),
              ),
            if (tmdbId != null)
              LibraryActions(
                tmdbId: tmdbId!,
                mediaType: mediaType,
                show: show,
                title: title,
              ),
          ],
        ),
      ),
    );
  }
}
