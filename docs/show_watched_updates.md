# Whole-show watched updates

The previous action waited for individual episode writes and a full refresh before
changing the UI, and allowed overlapping clicks. It also built episode numbers
from season counts, used episode one when a count was unknown, and excluded
season zero. Finally, a partial history containing only watched episodes could
be mistaken for a completely watched show.

The action now exposes an immediate local watched intent and busy indicator,
disables repeated clicks, and updates visible episode checks immediately. It
loads real season episode lists (including specials), deduplicates actual
season/episode keys, includes existing episodes with unknown air dates, and
excludes episodes with a known future air date. A season metadata failure stops
the action rather than guessing episode numbers.

The complete plan updates local history before backend writes, retaining watch
dates/counts on episodes already watched. Cached server refreshes are overlaid
with the pending local title so an older response cannot undo the optimistic UI.
Updates are isolated by profile/type/title; switching profiles stops further
writes to the original operation.

New backends receive atomic chunks of at most 100 episodes. Older backends with
no bulk endpoint use serialized individual writes. Both paths read back the
show's episode state, retry missing targets once, and only show success after
every planned target is confirmed. A failure restores/reconciles local state
and reports the error rather than claiming the entire show saved. Previously
committed chunks may remain saved, and retrying does not add another viewing to
episodes already complete. A show larger than 100 episodes is atomic per chunk,
not across the whole series.

Pending optional offline uploads are settled before the operation, discarded
for the title after success, and matching download progress is updated locally
without queuing new uploads. This action uses the manual history action lock.
Full-title multi-chunk Undo is not introduced by this change.

Validation:
    dart --enable-asserts --packages=.dart_tool/package_config.json test/show_watch_plan_checks.dart
Covers unknown season counts, non-contiguous numbering, specials, duplicate
metadata, future episodes, optimistic counts, incomplete backend readback,
bounded retries and network/metadata failures.
