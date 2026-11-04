# Persistent, versioned backend data

Requires backend PR #3 with migration 0023. The owner-only endpoint
GET /sync/:profile_id/versions returns generation, progress_version and
library_version. Each dataset's counter advances on writes and deletes.
Counters are materialized by SQL triggers, so checking versions is an indexed
lookup rather than a scan of watch history. Generation must be rotated after
restoring a database; see the backend recovery instructions.

Petal stores history, library and On Deck snapshots per server/account/profile.
The snapshot, generation and version live in one preference value. On launch,
saved data is rendered immediately and revalidated in the background. Matching
versions skip downloading that dataset. Changed data is replaced using the
existing read APIs, so deletions are reflected too. This first client integration
uses full replacements of changed datasets, not per-record incremental sync.
A new profile starts without another profile's visible data.

Version requests are shared across datasets and briefly cached for five seconds.
Ordinary repeated reads revalidate at most every 30 seconds. Local writes mark
their datasets dirty, invalidate the version check, and guard against older
in-flight requests overwriting newer data. Explicit refresh waits for validation;
ordinary cached reads keep displaying saved data while offline.

On Deck also refreshes after five minutes regardless of version. Home revalidates
on app resume and every five minutes while the app is active, including Upcoming,
because episode air dates can change without user writes. Artwork and TMDB
metadata retain their existing independent caches.

Backend 404/501 for /versions falls back to normal dataset reads. A temporary
network error preserves the displayed cache. Corrupt snapshots are discarded,
and a failed disk write does not hide successfully fetched data. An operator
must rotate the generation after restoring an older backend database.

Validation:
    dart --enable-asserts --packages=.dart_tool/package_config.json test/versioned_dataset_checks.dart
The checks cover unchanged versions, restored snapshots before network completion,
deletions, generation changes, timed refresh, profile/server isolation, stale
requests, older backends and unavailable storage.
