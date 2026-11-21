# Game design

## Confirmed requirements

- Name and tagline are `novadoku` and `A little puzzle. A little joy.`
- Flutter and Dart deliver a portrait mobile logic puzzle. Puzzle play, bundled assets, and fonts must work offline.
- Nova is the reference character with white fluffy fur, purple hair and fluffy tail, large purple eyes, pink inner ears, and a purple bandana with the N symbol. Match the original body proportions and premium 3D appearance.
- Place exactly one Nova in each row, column, and colored region. Two Novas must never touch, including diagonally. Each puzzle has exactly one solution.
- Each puzzle starts with three attempts. An incorrect Nova placement costs an attempt. Players can place Nova, mark cells with X, undo, use hints, and reset. Completing a puzzle unlocks the next level.
- The app must support difficulty progression, logical hints, daily challenges, and save and resume.
- Settings allow independent control of music, sound effects and haptics, plus Region patterns and Language. The in-app Reduced Motion preference was retired by the approved feedback audit on 2026-11-20; its legacy flag is ignored without changing other saved data.

The [UI specification](UI_SPECIFICATION.md) transcribes all reference copy and locates the original design. The [locked roadmap](MASTER_PROMPT.md) controls when each feature is built.

## Phase 01

The runnable title and tagline validate the app shell. Four named destination paths are registered, and reserved paths return to the root until their features are implemented. The app settings model uses the visible reference defaults (Music Off, Sound effects On, Haptics On, Reduced motion Off, Region patterns Off). Dimensional values, font identifications, and colors derived from the raster reference are estimates.

## Phase 02

The pure Dart engine generates unique 4 × 4 through 10 × 10 boards. Campaign chapters order puzzles using measured logical deductions. Daily puzzles are stable by UTC date. The engine uses three hints per session and supports preview, apply, cancel, undo, reset, retry, and a versioned snapshot. [Engine specification](GAME_ENGINE.md)

The reference board is a 6 × 6 example. Durable progress, save storage, final translations, and screen integration follow their scheduled phases.

## Phase 04

Home reads the current or next unlocked campaign level from the game session. Completing a level advances the Home badge and Play label. A Daily session leaves the in-memory campaign level in place. Play resumes an existing campaign session for the same level. Durable campaign progress follows Phase 08.

## Phase 06

Settings stores each switch independently. Language offers English, Hindi, Japanese, French, German, Russian, Portuguese and the system preference, with English fallback. All locales and their fallback fonts are bundled for offline use. Region patterns add independently recognizable cell markings to the existing region colors and numbers. [Localization](LOCALIZATION.md)

Daily play uses the UTC-day board from the engine. The current campaign session and most recently played daily session retain their own marks, attempts, hints, and completion in memory. A daily completion does not unlock a campaign level. Save and leave returns to the entry screen and keeps the session for the current app run. Durable progress follows the Phase 08 storage contract.

## Phase 08

Home restores the saved campaign level and unlocks at startup. The campaign and each UTC Daily date keep independent boards, move history, remaining budgets and completion information across restarts. Save and leave waits for a durable write. Settings keeps its existing defaults and reads preferences saved by earlier versions. [Progress storage](PROGRESS_STORAGE.md)


## Approved campaign difficulty refinement

New campaign puzzles use the v2 curve in [GAME_ENGINE.md](GAME_ENGINE.md#campaign-v2-progression): a very simple 4x4 Level 1, 24 forced-move practice levels, then gradually deeper visible elimination chains as grids grow to 10x10. Every accepted new campaign board is unique and logically finishable from its fixed Nova without trial placements or backtracking proofs. The curve includes introductory easing when the grid grows. Existing saves/completed levels, Daily play, artwork, presentation, controls and effects are preserved. Human difficulty calibration remains a future playtesting task; the automated rating measures actual deductions rather than grid size alone.

## Gameplay Hint confirmation (2026-11-20)

The existing round Hint control opens the reference bottom sheet rather than editing the puzzle immediately. Preview computes the existing pure useSmartHint transition without publishing it or writing progress. It shows a localized explanation for the first actual target: a visible Nova's row/column/region/adjacency exclusion, or the existing correct-Nova reveal fallback. The existing up-to-four-X selection and three-hint limit are unchanged.

Apply reruns the original controller action only if the session still matches the preview snapshot. The controller consumes one charge only when it successfully changes the puzzle. Cancel, barrier dismissal and Back leave the session, history, budgets and persistence unchanged. The selected cell is temporarily highlighted in place. The independent modal does not resize or reposition Gameplay, and its background scroll offset remains fixed. Duplicate openings/confirmation callbacks and stale previews are guarded. Existing feedback, highlight animations, completion flow and automatic progress saving execute through the original action path after confirmation.

## Home profile customization (2026-11-20)

The user-authorized Home profile modal provides eight free avatars, eight free frames and a locally editable username. Drafts preview immediately and persist only after Confirm through a separate profile key in the existing journal. Original Nova remains the default; other character/video players and game progress are untouched. See [profile specification and artwork provenance](PROFILE_SPEC.md).
