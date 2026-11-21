# novadoku development brief

Develop novadoku, a premium portrait mobile logic puzzle with the tagline “A little puzzle. A little joy.” Implement only the requested phase in the existing Flutter project. Use the [original reference sheet](reference/novadoku-ui.jpg) as the visual source of truth. Follow [AGENTS.md](../AGENTS.md) and preserve confirmed requirements and completed behavior.

## Locked ten-phase roadmap

1. Phase 01 — Complete project foundation
2. Phase 02 — Advanced gameplay engine
3. Phase 03 — Nova character and animations
4. Phase 04 — Home screen and navigation
5. Phase 05 — Complete gameplay screen
6. Phase 06 — All remaining screens
7. Phase 07 — Advanced animations, sound and haptics
8. Phase 08 — Progress and data management
9. Phase 09 — Complete testing and UI audit
10. Phase 10 — Final production build

## Phase 01 scope

| Location | Responsibility |
| --- | --- |
| `lib/main.dart`, `lib/app/` | Startup, portrait and edge-to-edge system UI, theme, routes, and provider wiring. |
| `lib/core/` | Constants, colors, typography, spacing and motion tokens, settings persistence and feedback contracts. Utilities and extensions are reserved for shared logic as it arises. |
| `lib/game_engine/` | Dart-only models and the boundaries for the generator, solver, validator, hints, and difficulty. |
| `lib/features/` | Home, gameplay, settings, daily challenge, tutorial, and progress boundaries. |
| `lib/shared/` | Responsive scaffold and background, controls, modal surfaces, and the future character integration directory. |
| `assets/` | Shipped fonts and licenses, plus directories reserved for approved art, animations, audio, and generated levels. |
| `test/`, `docs/` | Foundation verification and reference specifications. |

Phase 01 established the root and reserved destination names. Settings, Hint preview, Try again, Level complete, and Leave puzzle use the reusable dialog and sheet APIs when their screens are implemented. Mistake feedback is a gameplay state.

## Phase 02 scope

The pure Dart engine implements board validation and uniqueness, seeded campaign and daily generation, logical difficulty and hints, immutable gameplay and versioned snapshots. The Riverpod adapter serves the engine and moves expensive native work off the UI isolate. Phase 02 adds no package dependencies. [Gameplay engine](GAME_ENGINE.md)

## Phase 03 scope

Nova's reference-based artwork ships in seven transparent WebP stills and ten sprite atlases. The Flutter character widgets support expressions, looping, one-shot playback, preloading, and reduced motion using existing SDK APIs. [Animation specification](ANIMATION_SPEC.md) · [Artwork and source prompts](NOVA_ART.md)

## Phase 04 scope

Home renders the reference wordmark and pastel composition, plays Nova's existing idle and tap clips, and derives its campaign level from the game providers. Play prepares or resumes the current puzzle and passes the level to the Gameplay route. Settings, Daily challenge, and How to play are reserved for Phase 06. [Home design](UI_SPECIFICATION.md#1-home)

## Phase 05 scope

The Gameplay route renders the current session on 4 × 4 through 10 × 10 grids and uses the Phase 02 controller for moves, attempts, undo, reset, hints, completion, and failure. The screen includes placement and mistake feedback and reduced-motion behavior. Hint, outcome, and leave flows use functional shared dialogs that Phase 06 can replace with their approved layouts. Leaving retains the in-memory session. [Gameplay design](UI_SPECIFICATION.md#2-gameplay)

## Phase 06 scope

Settings, Hint preview, Try again, Level complete, Leave puzzle, Daily challenge, and How to play use the approved layouts. Mistake feedback stays in Gameplay. Daily and campaign retain independent sessions in memory. Settings control the bundled English locale, reduced motion, region patterns, and the saved feedback preferences. Phase 07 owns feedback playback and Phase 08 owns durable game progress. [Screen inventory](UI_SPECIFICATION.md#3-settings)

## Phase 07 scope

Motion uses the existing Nova poses with short interpolations and native Flutter gameplay and completion effects. The original bundled score and cues use audioplayers, independent playback settings, and foreground gating. Flutter system haptics follow game events. [Motion and feedback](ANIMATION_SPEC.md#phase-07-motion-and-feedback) · [Audio assets](AUDIO_ASSETS.md)

## Phase 08 scope

Campaign, UTC Daily sessions and Settings persist offline through a versioned two-generation journal. Startup restores the campaign, and Daily restores by date. Save and leave waits for the disk commit. [Progress storage](PROGRESS_STORAGE.md)

## Phase 09 scope

The UI audit renders all ten approved surfaces at phone, compact enlarged-text and tablet dimensions. Regression tests exercise all supported board sizes and every Nova clip. Background animation tickers pause outside the resumed lifecycle state. [QA results](QA_REPORT.md)

## Dependency decisions

| Package | Phase 01 decision |
| --- | --- |
| flutter_riverpod | Configure routing ownership, settings, and future game data through providers. |
| go_router | Register named paths and handle navigation lifecycle. |
| shared_preferences | Persist small independent settings offline using SharedPreferencesAsync. |
| flutter_localizations | Install SDK localization delegates. The sample UI is English. |
| flutter_test, flutter_lints | Use SDK widget tests and the starter lint configuration. |
| google_fonts | Bundle font files directly with licenses and explicit families for offline use. |
| flutter_animate | Flutter widgets and routes cover current transition requirements. |
| rive, lottie | Review alongside the delivered character and effect file formats in Phase 03 or 07. |
| audioplayers | Phase 07 uses it for a looping soundtrack and one priority-based effects channel. |
| sqflite | The Phase 08 record journal uses Dart files and the existing path_provider package. |
| flutter_svg | Evaluate when approved vector artwork requires it. |
| confetti | Phase 07 uses a bounded native Flutter canvas burst. |

Use built-in haptics. Preserve the existing stable Flutter and Dart toolchain. Keep the current scaffold package ID and default launcher artwork until production identifiers and launcher assets are provided.

## Verification

Execute `flutter pub get`, `dart format .`, `flutter analyze`, and `flutter test` after implementing the phase. Attempt an Android debug build when the toolchain supports it. Report tool results, assets still needed, and any verification limits. Continue to the next phase only when explicitly requested.

For game rules and implementation boundaries, see [game design](GAME_DESIGN.md), [game engine](GAME_ENGINE.md), [UI specification](UI_SPECIFICATION.md), and [animation specification](ANIMATION_SPEC.md).
