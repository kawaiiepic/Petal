# Code structure

Petal keeps UI components, data contracts, and API operations in separate files.
A stateful widget and its private `State` class belong together; unrelated widgets
get their own files. Files use `snake_case` and describe the component they contain.

| Directory | Responsibility |
| --- | --- |
| `lib/main.dart` | Startup and service initialization |
| `lib/app/` | App widget, theme wiring, and navigator keys |
| `lib/router/` | Routes and authentication redirects |
| `lib/navigation/` | App navigation and profile selection |
| `lib/pages/` | Route-level screens, named with `_page.dart` |
| `lib/pages/player/` | Playback screen and its controls |
| `lib/widgets/` | Focused UI components grouped by feature |
| `lib/widgets/home/` | Individual shelves and their cards |
| `lib/widgets/media/` | Shared caption-free media cards and shelf/grid layout |
| `lib/widgets/overview/` | Shared cast, season, recommendation, and title actions |
| `lib/api/backend/` | Petal backend, caches, library endpoints, and presence |
| `lib/api/tmdb/` | TMDB requests |
| `lib/api/trakt/` | Trakt import operations |
| `lib/api/imports/` | Pure import-file parsing helpers |
| `lib/models/` | Data contracts grouped by service or feature |
| `lib/theme/` | Theme preference and existing responsive typography |
| `lib/utils/` | Formatting, collection progress, notifications, and watch metadata |

Import the defining file when working inside the app. Model aggregate files such
as `models/tmdb/tmdb_models.dart`, `models/trakt/trakt_models.dart`, and
`models/media_state.dart` remain available when a caller needs the model family.
The aggregate files contain exports rather than implementations.

Data models do not belong in pages or API service files. Parsing helpers should
remain separate from network writes and progress orchestration. Shared widgets
such as `CastCard` and `PosterFallback` keep overview pages consistent.

The `/` route uses `pages/home_page.dart`. Artwork collections use `MediaShelf`,
which owns scroll controllers, spacing, sizing, and horizontal arrows. Its
`orientation` selects portrait or landscape cards, while `scrollDirection`
selects a horizontal row or a vertical grid. Vertical grids expand within a page
scroll view and scroll themselves when given a bounded height.

Each data adapter returns a `MediaCard` with an image URL, optional overlay,
accessibility label, and actions. Loading images, error images, hover behavior,
and clipping are shared. Captions are not rendered below artwork.

Give `MediaCard` a `MediaCardTarget` to enable the shared Play/Resume, Select Source,
More Info, Watchlist, Watched, and Rate menu. Shelf-specific commands belong in
`extraContextItems`; `showDefaultContextMenu: false` allows an extra-only menu.
Landscape cards automatically display TMDB title artwork at the top. English
artwork is preferred, then language-neutral artwork; missing logos are hidden.

```dart
MediaShelf(
  orientation: Orientation.landscape,
  scrollDirection: Axis.horizontal,
  itemCount: items.length,
  itemBuilder: (context, index) => MediaCard(
    imageUrl: items[index].image,
    label: items[index].showName,
    target: MediaCardTarget(tmdbId: items[index].tmdbId, type: MediaType.show),
    onTap: () => openEpisode(items[index]),
  ),
)
```

## Request caching

| Data | Freshness and behavior |
| --- | --- |
| TMDB requests, including title logos and episode details | Six hours; at most 256 request entries; simultaneous callers share work |
| Library rows | One minute, scoped to account/profile; invalidated after library writes |
| Watch history and next-up | One minute, scoped to account/profile; invalidated after progress writes |
| Artwork and logo files | Image/cache manager storage; PNG and SVG logo files share the disk cache |

Request caches are in memory and reset when the app restarts. Failed requests
are evicted for retry. Profile switches/logout clear displayed user data, and
late responses cannot replace another profile's results. Transient library load
failures retain already displayed values for the same profile.

User refreshes use `force: true`. Bulk watched/import writes suppress per-episode
next-up refreshes and reconcile once at the end. Completing a single title updates
both history and next-up. Cached reads do not repeatedly notify shelves when the
underlying result has not changed.

## Playback and downloads

`WatchProgress` defines the 90% watched threshold. Partial progress is retained for
resume and Home badges; merely starting an episode does not count it in watched
stats. `MediaCard` owns the shared in-progress indicator, including poster shelves
such as Liked, Stalled, and Most Watched. Show episode totals distinguish an
unfinished show between episodes from a fully watched show.

Downloads persist title/episode names and local playback progress in their device
index. Missing names from older downloads can be filled while browsing online.
`DownloadContextMenu` provides Play, View Show/Movie, and Delete actions. Deletion
cancels an active download and removes the local file as well as its index entry.

`PlaybackSource.resolve` returns an explicitly supplied stream immediately. Local
file sources bypass metadata and stream discovery. `StreamPlayer` and its controls
use saved labels, native tracks, and local progress for these sources: no backend
tracking, TMDB lookups, Discord metadata requests, online episode drawer, or next-up
discovery. Local progress is not queued for later backend synchronization.

`ExternalPlaybackSession` waits for a successful launch and an actual app
background/foreground round trip before asking whether the episode was finished.
Only explicit confirmation marks it watched; declining, launch failure, and profile
changes leave watched status unchanged.

Home cards use compact title logos and icon-only rating badges (thumbs-up for liked,
heart for loved). Upcoming and On Deck overlays include season/episode numbers or
`Movie`; Upcoming also includes watchlisted movie releases within its date window.
Movie and show heroes share working library actions. Their comments are embedded
below recommendations. Episode details expose a watched/unwatched context menu
that updates only the selected season and episode.

On Deck mixes resumes and untouched next episodes in one list, newest
`last_watched` first. Older backend payloads fall back to the latest available
watch-history activity. Partial playback also updates its local activity timestamp.
The shelf holds at most 12 distinct movie/show titles, fills spare slots from the
watchlist, and reserves one fresh watchlist suggestion whenever available. If all
saved titles already have progress, one saved title is retained with its resume
card. An empty watchlist simply leaves room for up to 12 active titles.

## Verification

```bash
flutter pub get
dart run git_stamp --build-type lite --limit 20 --adding-packages disabled
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/refactor_contracts_test.dart test/media_shelf_test.dart test/media_card_test.dart test/tmdb_logo_test.dart test/async_cache_test.dart test/request_caching_test.dart
flutter test test/watch_progress_test.dart test/external_playback_session_test.dart test/offline_download_test.dart test/home_progress_download_ui_test.dart test/home_overview_updates_test.dart
flutter test test/on_deck_selection_test.dart test/on_deck_shelf_test.dart
flutter test
```

The contract tests cover nested model decoding, download persistence, collection
status boundaries, and import format parsing. The media layout tests cover card
proportions and spacing, vertical scrolling, arrows, taps, overlays, accessibility
labels, and disposal. These tests do not make network requests.
The cache tests count mocked HTTP requests and cover concurrent reads, expiry,
forced refreshes, write invalidation, failure retries, and profile-switch races.
The playback/download tests additionally exercise the 90% boundary, external-player
lifecycle, offline source resolution with backend access blocked, local resume
persistence, file deletion, shared progress badges, and downloaded-file menus.
