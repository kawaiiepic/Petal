# Rewatching and watch counts

Movie, show and episode overview pages expose watch activity and Start rewatch.
A rewatch resets current progress while preserving past dates and lifetime counts.
The next completed viewing adds one count. Use Undo to revert the reset before
new playback changes the title. Full-title rewatch resets matching downloaded
progress and clears that title's pending offline uploads; unrelated titles and
movie/show IDs remain separate.

Movies and episodes show lifetime counts. Shows show total episode watches and
the minimum watch count across every aired regular episode. Specials are counted
as episodes but excluded from full-show counts. Ongoing shows gaining new episodes
can lower the all-aired-episodes count until those episodes are watched.
A missing aired episode counts as zero. Historical counters without dates are
preserved; duplicate title rows are not added together.

Requires backend sessions/sync/bulk/data-jobs PR and its migrations. This client
PR is stacked on the pagination/presence compatibility branch (PR #4).
The normal Play action remains available; Start rewatch explicitly starts a new
viewing cycle at zero. The full-title action supports shows larger than a season
without issuing one request per episode.

Validation:
    flutter test test/watch_counts_test.dart
    dart analyze lib/utils/watch_counts.dart lib/widgets/overview/watch_activity_panel.dart lib/api/history_actions.dart lib/api/offline_progress_sync.dart lib/pages/movie_overview_page.dart lib/pages/show_overview_page.dart lib/pages/episode_detail_page.dart
