import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/widgets/overview/library_action_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LibraryActions extends StatelessWidget {
  final int tmdbId;
  final MediaType mediaType;
  final TmdbShow? show;
  final String? title;

  const LibraryActions({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    this.show,
    this.title,
  });

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
            return LibraryActionButton(
              icon: LucideIcons.check,
              active: watched,
              onTap: () =>
                  UserLibrary.toggleWatched(tmdbId, mediaType, show: show),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            final saved = UserLibrary.isInWatchlist(tmdbId, mediaType);
            return LibraryActionButton(
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
            return LibraryActionButton(
              icon: icon,
              active: rating != TitleRating.none,
              onTap: () => UserLibrary.cycleRating(tmdbId, mediaType),
            );
          },
        ),
      ],
    );
  }
}
