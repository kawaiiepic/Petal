import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LibraryActions extends StatelessWidget {
  final int tmdbId;
  final MediaType mediaType;
  final TmdbShow? show;
  final String? title;

  const LibraryActions({super.key, required this.tmdbId, required this.mediaType, this.show, this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ValueListenableBuilder(
          valueListenable: BackendCache.watchHistory,
          builder: (context, _, __) {
            final watched = UserLibrary.isWatched(tmdbId, mediaType);
            return _RoundAction(
              icon: LucideIcons.check,
              active: watched,
              onTap: () => UserLibrary.toggleWatched(tmdbId, mediaType, show: show),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            final saved = UserLibrary.isInWatchlist(tmdbId, mediaType);
            return _RoundAction(
              icon: LucideIcons.bookmark,
              active: saved,
              onTap: () => UserLibrary.toggleWatchlist(tmdbId, mediaType),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: UserLibrary.ratings,
          builder: (context, _, __) {
            final rating = UserLibrary.ratingFor(tmdbId, mediaType);
            final icon = switch (rating) {
              TitleRating.none => LucideIcons.thumbsUp,
              TitleRating.like => LucideIcons.thumbsUp,
              TitleRating.love => LucideIcons.heart,
            };
            return _RoundAction(
              icon: icon,
              active: rating != TitleRating.none,
              onTap: () => UserLibrary.cycleRating(tmdbId, mediaType),
            );
          },
        ),
        _RoundAction(
          icon: LucideIcons.messageCircle,
          active: false,
          onTap: () {
            final type = mediaType == MediaType.movie ? 'movie' : 'show';
            final label = Uri.encodeComponent(title?.trim().isNotEmpty == true ? title! : 'Comments');
            context.push('/comments?type=$type&tmdb=$tmdbId&title=$label');
          },
        ),
      ],
    );
  }
}

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
            if (tmdbId != null) LibraryActions(tmdbId: tmdbId!, mediaType: mediaType, show: show, title: title),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _RoundAction({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      style: (active ? const ButtonStyle.primary() : const ButtonStyle.outline()).withBorderRadius(
        borderRadius: BorderRadius.circular(16),
        hoverBorderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 18),
    );
  }
}
