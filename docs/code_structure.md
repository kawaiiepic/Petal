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

```dart
MediaShelf(
  orientation: Orientation.landscape,
  scrollDirection: Axis.horizontal,
  itemCount: items.length,
  itemBuilder: (context, index) => MediaCard(
    imageUrl: items[index].image,
    label: items[index].showName,
    onTap: () => openEpisode(items[index]),
  ),
)
```

## Verification

```bash
flutter pub get
dart run git_stamp --build-type lite --limit 20 --adding-packages disabled
dart format --output=none --set-exit-if-changed lib test/refactor_contracts_test.dart test/media_shelf_test.dart
flutter analyze
flutter test test/refactor_contracts_test.dart test/media_shelf_test.dart
flutter test
```

The contract tests cover nested model decoding, download persistence, collection
status boundaries, and import format parsing. The media layout tests cover card
proportions and spacing, vertical scrolling, arrows, taps, overlays, accessibility
labels, and disposal. These tests do not make network requests.
