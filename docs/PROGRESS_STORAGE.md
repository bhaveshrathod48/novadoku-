# Offline progress storage

Phase 08 stores campaign, each UTC Daily challenge, and Settings as separate records. Native builds use the app-private application support directory. Web builds use browser-local storage through the existing SharedPreferences plugin. Neither path requires a network connection.

## Records and restoration

- `campaign` combines the current session, highest unlocked level, and deduplicated completed levels. Completing a level saves the board and unlock together. Startup restores the record before building Home, so its level badge starts on the saved level or the next unlocked level.
- `daily-<UTC day>` stores one session per challenge day and the UTC completion timestamp. A new day starts its own puzzle and leaves earlier days intact. Daily play leaves campaign completion and unlocks intact.
- `settings` stores audio, haptic, region-pattern and language preferences. The retired in-app reduced-motion flag is ignored on read and omitted on the next Settings write, without a schema change or progress reset. Installs with the older Settings key read it until a journal record exists.
- A puzzle session stores the exact generated board, input mode, attempt and hint budgets, and the edit history. Restore re-verifies uniqueness, replays the marks and reconstructs undo. Session schema v2 also stores the fixed starting Nova and protected red X cells; v1 sessions restore without adding a new given. Schema v3 adds the remaining Nova reveal counter (0–4); v1/v2 records gain four uses on restore without altering existing progress. The journal accepts all three session versions and retains its existing record/checksum format. Hint previews and the last mistake banner are transient.

## Recovery and writes

Each key has two alternating revisions. Records include a schema version, key, revision, payload and Adler-32 checksum. On native devices the writer first flushes a temporary file, then renames it over the inactive generation. Restore ignores temporary files, validates both generations, and uses the newest acceptable record. A damaged record falls back to the earlier generation or the normal starting state for that key. Recognized future schemas are preserved and refused. Adler-32 detects accidental damage.

A single writer serializes changes and keeps the latest staged state for each key. Meaningful actions schedule saves immediately. Save and leave and campaign result navigation wait for the active record to commit. Lifecycle changes retry pending work. If a write fails, the last committed copy remains available and the latest game state stays pending for retry. Settings reverts failed edits while keeping later pending changes. The app can restore the last committed generation after termination. A hard kill before a pending commit or the operating system clearing local app data can still lose unsaved changes.

Run `flutter test test/progress_storage_test.dart test/gameplay_screen_test.dart` for file-backed restart, rollover, corruption, write ordering, settings and save-before-leave coverage.
