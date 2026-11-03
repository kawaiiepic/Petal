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

Media artwork has separate loading and unavailable states. `MediaCard.isLoading`
hides overlays and disables interactions while metadata loads; image requests use
the same artwork skeleton and stop animating on failure. Overview failures expose
retry controls instead of permanent skeletons. Finished badges require all regular
episodes to meet the 90% watched threshold and a known episode total.

Collections resolve metadata through a bounded queue before splitting Watching,
Watched, and Planned rows. Cards never remove their own allocated slots, and
missing posters or failed metadata stay visible with fallback artwork.

Backend cache notifiers store values immediately and defer widget notifications
until the end of the frame during build/disposal. This lets final player progress
saves update shared state without rebuilding a locked widget tree.

Shared media cards and movie/episode overviews display a determinate progress bar
for partial playback of that exact movie or episode. Bars read existing caches,
make no requests, and hide for unstarted or watched (90%+) items. A show-level card
does not display an aggregate episode ratio.

On Deck opens the selected episode overview or movie overview. Watchlist show
suggestions open the first regular season's first episode. Resume and Restart stay
available in the context menu; overview Play uses the cached resume position.
Continue Watching and In Progress shelves retain direct resume playback.

The player seek slider commits its final drag value on pointer release even when
shadcn suppresses an equal-value `onChangeEnd` callback. A release sends one seek;
cancellation sends none. It awaits the native command, handles failure, and ignores
outdated command completions after another seek or a player change. Position and
buffer events are unthrottled; interpolation stops while dragging, seeking,
paused, hidden, or buffering and respects playback rate. Unknown durations disable
the slider instead of dividing by zero.

The player Info button toggles a scrollable diagnostics panel over the video.
It refreshes local player state once a second while open, works offline, exposes
no source URLs/headers, and stops its timer when closed. Controls stay visible
while diagnostics are open. It shows playback/buffer state, buffered endpoint and
seconds ahead, codec/decoder/format, resolution, source FPS, audio and subtitle
information. Buffer readiness is distinct from the media's buffered percentage.

The seek bar paints a separate light-gray buffered layer below playback progress.
The empty track is translucent, so the buffered extent remains visible instead of
sharing the empty track's color. It uses the native absolute buffer endpoint,
updates immediately on buffer events, clamps to duration, and ignores gestures.

Up Next uses a 16:9 card capped at 320 px and constrained to the player's available
width/height above its controls. Cancel autoplay dismisses it for the current
playback item, including after seeks, control visibility changes, and diagnostics.
The 45-second countdown starts only near the end with valid next-episode metadata;
it pauses while playback is paused, buffering, or the panel is suppressed. It may
finish after EOF, and manual play cancels its timer to prevent a duplicate launch.
A new playback item resets dismissal. Hidden cards do not intercept input.

Autoplay and Skip Next request a new episode through `PlaybackScope`, leaving the
existing `StreamPlayer`, native `Player`, `VideoController`, and controls mounted.
The outgoing episode is paused/saved before the active playback item changes.
Tracking and resume flags reset for the new episode; native progress events are
ignored while switching to avoid attributing old positions to the new episode.

`PlaybackMediaSession` opens each source paused, restores volume, prepares tracks
and resume, then starts playback. Device-local `PlaybackVolumeStore` persists user
volume/mute changes (including the last audible volume) for future sessions and
works offline. A volume adjustment made during source loading wins over the prior
value. Opening failures never start playback at the backend's default volume.

Playback recovery retains the active media, last confirmed position, volume, and
saved language settings. Retry reopens the same source; Choose another source
fetches fresh candidates without replacing the player. Downloads only offer local
retry. Recovery exits fullscreen to show its controls, and pending old-media events
cannot mark the new playback item watched during a transition.

Playback preferences are device-local: preferred audio/subtitle language,
subtitles enabled, speed (0.25–3×), and native subtitle delay (±60 seconds). Settings
and the player menu expose an editor; explicit track selections remember their
language. ISO aliases/regional codes are supported. The fullscreen button uses the
video controller's fullscreen API. Player shortcuts: Space/K play, arrows/J/L seek,
up/down volume, M mute, S subtitles, F fullscreen, Esc exit, +/- speed, [/] delay.
Text entry and modifier shortcuts are excluded.

Customize Home (Home header or Settings) shows/hides and reorders sections,
including separate Recent/Stalled/Rewatched entries and addon catalogs as a group.
Start now is hidden by default. The editor stays reachable with every shelf hidden.

Downloads display persisted byte counts, actual disk usage, and free space using
local desktop queries or Android/iOS storage channels. Interrupted/missing files
become retryable failures. Retry restarts a download; Find new source refreshes its
source. Partial-file paths are indexed before transfer so removal also cleans them.

Offline progress sync is disabled by default. Enabling it queues future downloaded
watch updates with the original account/profile. Playback records locally and
suspends uploads; background retries run separately every 30 seconds when signed
in, or after backend recovery/manual Sync now. Failed uploads remain queued, newer
local revisions survive an in-flight upload, and known farther-ahead server
progress is retained. Turning sync off clears pending uploads. Playback itself
never performs backend tracking or discovery for local files.

## Verification

```bash
flutter pub get
dart run git_stamp --build-type lite --limit 20 --adding-packages disabled
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/refactor_contracts_test.dart test/media_shelf_test.dart test/media_card_test.dart test/tmdb_logo_test.dart test/async_cache_test.dart test/request_caching_test.dart
flutter test test/watch_progress_test.dart test/external_playback_session_test.dart test/offline_download_test.dart test/home_progress_download_ui_test.dart test/home_overview_updates_test.dart
flutter test test/on_deck_selection_test.dart test/on_deck_shelf_test.dart
flutter test test/completion_skeleton_collection_test.dart test/frame_safe_value_notifier_test.dart
flutter test test/media_playback_progress_test.dart
flutter test test/seek_slider_test.dart
flutter test test/player_debug_buffer_test.dart
flutter test test/next_up_card_test.dart
flutter test test/playback_session_volume_test.dart
flutter test test/media_feature_services_test.dart test/media_feature_widgets_test.dart test/player_shortcuts_test.dart
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

### Subtitle appearance, downloads, and history controls

Playback preferences now persist subtitle font size, outline, background, and
bottom offset. Settings and the player preference dialog share these controls;
changes update the existing Video rather than replacing the player.

Downloads use a FIFO queue with pause/resume and move-earlier controls. Partial
files are kept on pause. HTTP resume uses Range and If-Range with a saved strong
ETag or Last-Modified validator; unsupported ranges restart safely, invalid
ranges fail without appending, and truncated responses are not marked complete.
Queued/running work restored after an app restart is paused for explicit resume.
Download season on show overview queues aired episodes without duplicating saved
items. Wi-Fi-only is device-local, persists across restarts, polls the connection,
pauses transfers when Wi-Fi is lost, and resumes queued work when Wi-Fi returns.
Android/iOS use native network checks; desktop uses local operating-system tools.
Unknown network status waits rather than assuming Wi-Fi. Linux requires nmcli
for automatic Wi-Fi detection. Local-file copies do not require Wi-Fi.

Manage playback history is available from Settings and shared card menus. It
supports per-movie/episode progress reset, watched/unwatched, and undo of the
latest manual progress edit in this session. Episode/card watched actions and
movie library actions use the same undo service. Edits are bound to the original
profile, wait for any active optional sync, discard the affected pending upload,
and update matching downloaded playback progress locally without queuing an
upload. Undo refuses to overwrite newer remote progress. History edits now use the owned-profile /track/history endpoints from
petal-backend PR #1. Remove history, remove one play, reset, and watched/unwatched
create server snapshots; Undo restores records, timestamps, and counts for one
day unless newer progress changed the title. Pending sync and changed local
download progress also block stale undo. Reset/delete clear the matching queued
offline update, including when a profile switch happens during the request.
The backend requires migration 0016 and JWT_SECRET configuration/deployment
before these client controls work. Background tracking keeps PUT /track/state.
Show-wide bulk tracking starts deferred jobs in bounded pairs rather than
starting every episode request before awaiting a chunk.
