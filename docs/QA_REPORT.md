# Phase 09 QA report

Audit date 19 November 2026. Scope follows the locked roadmap.

## Executed verification

- Offline dependency resolution succeeded.
- Formatting completed and Flutter analysis reported no issues.
- The complete suite passed all 78 tests.
- Android debug APK built successfully at `build/app/outputs/flutter-apk/app-debug.apk`.
- The successful build emitted an Android SDK XML metadata version warning. The Android Studio and command-line SDK tools need alignment before final production verification.
- ADB reported zero attached devices. The Android SDK reported zero configured emulators.

## UI audit

Rendered all ten reference surfaces at 390 × 844, 320 × 568 with 200% text, and 800 × 1280. Captures use the bundled Fredoka, Nunito, icons and Nova assets with real generated puzzles and accessible system insets. All layouts completed without framework layout errors, and tested actions remained reachable through scrolling.

Compared phone captures against the original sheet for colors, typography hierarchy, line icons, spacing, alignment, corners, gradients, shadows, dialog bounds and Nova identity. The composition follows the reference. The generated region arrangement and logical hint differ with each puzzle. Existing font approximations and reconstructed Nova artwork retain small differences in facial shading, highlights, expression and proportions. These are visible in the comparisons and predate this audit. Captures leave system bars to the operating system.

Reproduce the 30 captures with:

```sh
flutter test --dart-define=QA_CAPTURE=true test/ui_audit_test.dart
python tool/compare_ui.py
```

Images are written under `build/qa09/`. The two comparison sheets pair each reference panel with its current Flutter render.

## Functional and effects coverage

Tests cover complete UI play at every size from 4 × 4 through 10 × 10, independent uniqueness verification for 112 generated puzzles, rule validation, Nova and X placement, attempts, preview/apply/cancel hints, undo budgets, reset, retry, completion, unlocks, navigation, settings, independent Daily sessions and UTC rollover. File-backed restart tests reconstruct the exact board, marks, budgets and undo history, and check corruption fallback, interrupted-write remnants, future versions, concurrent writes, and save-before-leave.

Every Nova clip is now individually checked for changing rendered pixels, completion or looping behavior, and ticker disposal. Tests also cover missing artwork, rapid expression changes, reduced motion, placement reactions, shaking, hint glow and one-shot celebration. Audio tests verify all ten bundled PCM assets, seam continuity in the score, cue scheduling, priority, muting during preparation, lifecycle gating and platform haptic dispatch. Audio output and physical haptic strength require device checks.

## Confirmed fix

Added an explicit foreground TickerMode around the application. Nova and other animation controllers now mute their tickers while the app is inactive, hidden or paused and resume when foregrounded. Regression assertions verify that background tickers are disabled and restored. The existing audio lifecycle gating continues independently.

Updated an outdated UI asset note to reflect the shipped music, sound effects and Flutter celebration particles. No dependency or asset was removed without confirmed evidence that it was unused.

## Host performance observations

During the full concurrent test run, generating 112 puzzles took 1526.68 ms total with a 50.67 ms maximum per puzzle. Independent validation brought elapsed time to 1645 ms. The slowest four-board chapter took 564.94 ms. Native generation and hint computation remain on the worker isolate.

The seventeen Nova textures occupy 2,155,740 compressed bytes. Serial host decoding took 244.9 ms, with 23.0 ms for the slowest texture. Existing atlas bounds, lazy loading, repaint boundaries, listener disposal and audio channel limits remain covered or inspected.

These host figures do not measure device startup, frame pacing, resident memory or battery drain. Those require profile-mode measurements on supported hardware. No device measurements were available.

## Remaining verification and Phase 10 readiness

The automated audit and Android debug build pass. Phase 10 can proceed with device verification pending. Android force-stop and relaunch, audible loop continuity, speaker and Bluetooth balance, physical haptics, cold startup, sustained frame timing, resident memory and battery consumption remain unverified. Existing file-backed restart tests do not replace an Android force-stop test. A process killed before its pending save commits can lose that latest action.

Production launcher artwork and production build identifiers remain the Phase 10 items already recorded in the master brief.
