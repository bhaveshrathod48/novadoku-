# Animation, feedback, and asset integration

## Shared UI click replacement (2026-11-20)

All button, selection and navigation cues now use the supplied offline
`assets/music/Ui click btn.mp3` at the existing 0.20 UI volume. The original
unused button.wav and its synthesis call are removed. The MP3 is bundled and
predecoded on the existing low-latency platform path, with one retained UI
player, separate from the unchanged gameplay-effects channel and music.
Each UI restart stops the previous click, stale queued starts are discarded,
and mute/lifecycle/disposal invalidate pending playback. Route notifications
still coalesce with control clicks; separate rapid control clicks are allowed.

Gameplay's Nova/Hint power buttons and Apply hint explicitly request the UI
sound without extra haptics. Their existing resulting placement/hint sounds
and haptics remain independent and unchanged. Puzzle taps, double taps,
swipes, correct/wrong placement, heartbreak, victory and music keep their
original assets, volumes, timing and event ordering. No video player or UI
layout changes are part of this update.

Verification: flutter analyze is clean and all 118 focused audio, navigation,
Gameplay, Home, profile and widget tests passed. Tests cover bundled MP3
mapping, 40 rapid UI clicks, a 100-request burst, single UI voice, mute and
disposal, uninterrupted gameplay cue sequences and preserved hint haptics.
Physical-device audible latency and balance remain unverified. No production
build was created.

## Navigation and haptic audit (2026-11-20)

The in-app Reduced Motion switch, settings field, persistence flag and localized
label are retired. Old flags are ignored; other preferences and progress retain
their existing storage format. Normal animation durations, videos and playback
logic remain unchanged. Flutter's independent operating-system accessibility
handling remains intact; it no longer depends on a saved game preference.

Actual Navigator pushes, pops, removals and replacements provide forward/back
feedback, including system Back and barrier dismissals. Initial route stacks
are silent. Navigation reuses the original button.wav at its original volume;
it is predecoded alongside the retained short effects. Same-turn button/route
notifications coalesce, and 90 ms UI feedback suppression prevents duplicate
clicks. Stale UI sound starts are dropped rather than queued after navigation.
Navigation never awaits audio or haptics.

Native selectionClick supplements light, medium, success and error cues.
Profile avatar/frame/tab and Settings option selection use selection feedback;
correct player placements use success feedback. Light haptics are limited to
one per 65 ms, with a 180 ms cooldown after success/error cues and no queued
native calls. Important feedback can supersede a recent light cue. Settings,
foreground state and disposal gate both channels. Gameplay sound assets, cue
lists, volumes, durations, X event dispatch and music behavior are preserved.

Verification: flutter analyze is clean; the complete flutter test suite passed
297 tests with concurrency limited to two. Coverage includes native haptic
method mappings, route push/pop/replace and barrier dismissal, UI feedback
deduplication, burst input, settings gating, legacy flags, offline progress,
all grid sizes and locked video timing. The video test's native prefetch wait
was made independent of decoder scheduling while retaining its exact 35/37 ms
frame assertions. A connected Android phone was detected, but updated-app
audible latency, vibration strength and physical frame pacing were not tested.
No production build was created.

## Home Nova ambient backdrop (2026-11-20)

Home adds a nine-second looping particle theme behind its existing hero:
colorful stars, sparkles, tiny paw prints, pastel glowing motes and a breathing
lavender radial glow. The existing video busy callback ramps the effect up over
280 ms when a tap reaction is accepted, keeps it enhanced through the queued
idle finish and full jump, then eases back over 500 ms after completion or
cancellation. No video player, clip, speed, tap command or character geometry
changes. Particles stay in the hero slot, behind the portrait and away from
other content. Reduced motion suppresses the boost and uses static decoration;
the existing lifecycle, route visibility and disposal handling applies.

## Nova ambient particle backdrops (2026-11-20)

Four bounded native Canvas themes decorate the existing character slots:
Try Again uses broken hearts, lavender motes and sparkles; Level Complete uses
colorful confetti, gold stars, sparkles and a soft victory glow; Daily Challenge
uses gold stars, magical rings and glowing motes; How to Play uses pastel puzzle
squares, paw prints and stars. Their gentle continuous clocks last 10, 7, 6 and
8 seconds respectively, with fading, drifting and scaling particles.

All decoration paints behind Nova, stays within the existing character area,
and reserves a clear central portrait area. The existing result celebration
burst is retained behind Nova and clipped to its portrait slot. No video asset,
player, playback speed, character transform, screen layout or audio is changed.
Cached paths and deterministic particle descriptors share one painter design;
particle ticks repaint without rebuilding the video child. Reduced motion uses
a static low-opacity arrangement. Clocks pause while backgrounded, off-route or
under disabled TickerMode, and dispose with their widgets.

All 98 focused particle, responsive-layout, video, Gameplay and UI-audit tests
passed. Widget tests cover all four themes, stable child geometry and build counts,
pointer passthrough, reduced motion, lifecycle pause/resume and disposal.
Phone screenshots of the four affected scenes were inspected for character,
text and button clearance. Physical-device frame timing remains unverified;
no production build is created for this change.

## Explicit heart-stage timing (2026-11-20)

This timing-only refinement supersedes the 850 ms cadence below. The existing
rose heart appears over 250 ms, holds fully visible for 200 ms, cracks over
350 ms, then breaks and fades over 500 ms. These stages occupy 0-250, 250-450,
450-800 and 800-1300 ms respectively. The existing red-X draw follows over
170 ms, for a total finite clock of 1470 ms. Easing, colors, glyph geometry,
background/pattern restoration, sound dispatch and gameplay remain unchanged.
The existing shared-duration failure wait now completes after the longer
sequence. Earlier incorrect cells continue animating while inputs proceed;
restored cells and reduced motion retain their immediate final-state behavior.

Verification: flutter analyze reported no issues; all 96 focused mistake,
Gameplay, motion and audio tests passed, including exact stage constants, the
visible hold, no early X draw, independent rapid mistakes, reduced motion,
disposal and waiting for the completed sequence before Try Again. No production
build was created.

## Rose-red mistake refinement (2026-11-20)

This supersedes the 640 ms incorrect-cell sequence below. The single cell clock
now runs for 850 ms: heart appearance/pop through 210 ms, crack from 240-350 ms,
split from 350-570 ms, and smooth heart/particle fade through 650 ms. A quiet
rose-tinted backdrop restores the original region gradient and pattern by
670 ms. The heart, particles and incorrect X use the existing rose-red error
color; no other palette values or audio cues change.

The permanent error border is removed only for Gameplay's restored-region
mistake cells; their normal region edge remains. The wrong X draws from
680-850 ms using the exact same GameplayCross painter, ease-out stroke progress,
rounded caps, thickness, fade and pop curve as the normal white X. Optional
animation input adds no changed behavior to normal marks. Persistent wrong-X
protection, attempts, sounds, controls and correct Nova/video players are intact.
The existing failure wait follows the shared 850 ms duration, so the Try Again
dialog opens after the effect; reduced motion still skips the sequence.

Verification: flutter analyze reported no issues; all 140 focused tests passed.
Pixel masks match normal-X stroke geometry at five draw phases. Tests cover
rose heart/X colors, restored patterns and normal border, all three mistakes
across sizes 4-10, uninterrupted/reduced-motion playback, disposal, immediate
state/audio events, the delayed failure dialog, gestures and existing Nova
effects. Updated phase images under build/mistake_effect were inspected, as
were samples from the supplied refinement recording. Device timing remains
unverified. No production build was created.

## Incorrect-placement reference sequence (2026-11-20)

Every newly rejected Gameplay Nova placement uses a 640 ms cell-local sequence:
coral flash, centered white-heart pop, crack near 170 ms, split/particles near
230 ms, region restoration from 350-530 ms, then red-X fade/bounce from about
467-640 ms. The existing header heart-loss effect starts with the same attempt
update, and the existing wrong-placement/heart-loss audio dispatch is unchanged.
This replaces the earlier second-mistake-only above-cell heart; the header
heart effect remains unchanged. Existing red-X borders and protection remain.

Gameplay rejected cells retain their original region gradient and the existing
pattern preference beneath the transient effect. A shared-cell opt-in preserves
the original mistake surface for all other consumers. Normal white Xs, gesture
behavior, region motifs, character assets and Nova decoding/playback are untouched.

Each rejected cell owns a finite disposed clock. Later inputs may clear the
board-level reaction without truncating that cell's sequence. Restored rejected
cells display their final X without replay; reduced motion finishes immediately.
On the third mistake, attempts/failure/save state and sound dispatch still occur
immediately, while Try Again presentation waits for the cell's 640 ms effect.
The existing cancellable outcome wait handles disposal. Rapid reversals exposed
a duplicate-key issue in the existing banner fade; an unkeyed transition wrapper
now lets AnimatedSwitcher assign distinct entry keys without a visual change.

Validation: flutter analyze reported no issues. All 139 focused mistake, pattern,
Gameplay, motion, Nova, reward, audio and shared-widget tests passed. Coverage
includes three independent rapid mistakes for every size 4-10, immediate attempt
and sound events, failure-dialog timing, restoration, reduced motion, disposal,
and rendered heart/coral/red-X phases. The supplied 191-frame reference was sampled
for motion comparison; app effect captures are in build/mistake_effect. Device
audio latency and GPU frame pacing remain unverified. No production build created.

The Gameplay-only [presentation feedback refinement](GAMEPLAY_FEEDBACK.md)
documents heart breaks, reveal sparkles, player-only combos, logical-X praise,
unit milestones, completion messages and the stable mistake banner. Its full
verification passed 263 tests with clean analysis; existing audio and Nova video
playback implementations remain unchanged.

## Phase 01 implementation

| Interaction | Configuration |
| --- | --- |
| Press | 110 ms ease-out to 97% scale. Pointer cancellation and disabling release the pressed state. |
| Toggle and mode selection | 160 ms ease-out cubic. |
| Dialog | 240 ms entrance, 180 ms exit. Fade and scale between 96% and 100%, with the custom scrim. |
| Bottom sheet | 300 ms entrance and 220 ms exit using Flutter's modal route and drag behavior. |
| Grid appearance | 180 ms color and border transition for hint and mistake appearances. |
| Attempts | 220 ms ease-out cubic interpolation between filled and spent hearts. |
| Indeterminate loading | A steady partial ring when reduced motion is enabled. |

App motion retains Flutter's system accessibility handling. The former saved game preference was removed in the navigation and haptic audit above. System accessibility can apply final visual states and zero modal timing. User-driven scrolling and sheet dragging are direct manipulation.

## Phase 03 character playback

| Clip | Behavior and poses |
| --- | --- |
| `nova_idle` | Loops through standing, lifted chest and tail, blink, and reopened eyes. |
| `nova_happy` | Plays once from a smile through a raised paw and open laugh. |
| `nova_tap_reaction` | Plays once through a crouch, articulated hop, and bent-knee landing. |
| `nova_correct` | Plays once through perked eyes and an open-mouth grin. |
| `nova_wrong` | Plays once through a lowered gaze, drooped ears, and a soft frown. |
| `nova_thinking` | Loops through a curious gaze, raised brow, and blink. |
| `nova_celebration` | Plays once through an excited portrait laugh and settle. |
| `nova_try_again` | Plays once from a sad seated look to a reassuring closed-eye smile. |
| `nova_daily_challenge` | Loops through a play bow, weight shift, tail flick, and paw lift. |
| `nova_sleeping` | Loops through curled sleeping poses with subtle chest, ear, and tail changes. |

Use `NovaArtworkImage` for hero art, avatars, grid marks, and dialog stills. Use `NovaCharacter` for a clip. The caller owns the optional `NovaCharacterController`. For example, `controller.play(NovaExpression.tapReaction, then: NovaExpression.idle)` plays a hop and resumes idle. Single-play clips hold the final pose when the caller omits a follow-up. Reduced motion and `animate: false` show the expression's representative still and skip playback callbacks and automatic follow-ups. Changes across expressions use the shared 180 ms fade after the new atlas decodes.

Call `NovaAssets.preload` for the art and clips required on the next surface. Flutter shares the cached textures. Each clip loads one 768 × 768 atlas (2.25 MiB decoded RGBA), or one 512 × 512 atlas (1 MiB for Correct and Wrong). During a transition a character holds one outgoing atlas in addition to the current one. Pose changes repaint a boundary. The widget releases listeners, tickers, and decoded-image handles on teardown. Load errors report through `onAssetError` or Flutter error reporting. [Flutter image ownership](https://api.flutter.dev/flutter/dart-ui/Image-class.html) · [Artwork and source prompts](NOVA_ART.md)

Run `flutter test test/nova_character_test.dart --reporter expanded` to check offline decoding, transparency, pose changes, loops, expression handoff, reduced motion, missing assets, and disposal, and to reproduce the host decode benchmark. On-device frame pacing remains a verification item when the screens use these widgets.

## Phase 05 gameplay feedback

Nova placement and X marks originally used a short fade and pop; the gameplay-only reference-motion update below replaces those entrance effects. A rejected placement shakes the target cell over 270 ms, fades the spent heart, and briefly plays Nova's wrong reaction on a placed Nova when one is visible. Correct placements use Nova's correct clip. The hint target stays outlined during preview and briefly after apply. Reduced motion shows static marks and feedback and skips movement. [Gameplay interaction rules](GAME_ENGINE.md)

## Phase 06 surfaces

Hint preview loops Thinking, Try again plays its reassuring pose sequence, and Level complete plays Celebration. Daily challenge loops the play-bow sequence. The saved and system reduced-motion preferences select representative stills and zero-duration modal transitions through the existing motion and character widgets.

## Phase 07 motion and feedback

Nova interpolates the existing authored poses during the breathing and tail transitions, uses short blink transitions, and crossfades between expressions. Atlas loading holds the relevant existing still where provided. Holds do not trigger sprite repaints. Character artwork, scale and screen layout follow the existing visual specification.

Gameplay uses spring mark placement, a damped mistake shake, a heart-loss pulse and fade, and a warm hint glow. The white hint outline remains visible throughout the preview. A 1.55-second confetti and sparkle burst plays on a new completion within the outcome artwork. The result card and board remain in their reference positions. Press release uses a small spring and routed screens use a short fade and slide. Reduced motion uses the existing stills and static feedback, skips the burst and glow, and uses immediate route and modal transitions.

The app dispatches contextual sound and system haptics from successful controls and real game events. A rejected placement emits one error haptic and queues wrong placement plus heart loss. Failure adds its own cue. A completion emits one success haptic and queues its fanfare after the placement or hint cue. Previewing and cancelling a hint leave the activation cue for Apply hint. Levels opened in a terminal state skip the new-completion burst and audio. Music, effects, and haptics are gated independently by Settings and foreground state. [Original audio and playback](AUDIO_ASSETS.md)


## Gameplay performance validation

The current optimization keeps all existing animation durations, curves, artwork, sounds, music, feedback timing and gameplay transitions. The original single-tap X cue remains deferred during double-tap disambiguation. No additional sound cues, players, low-latency playback mode, expiry deadlines or alternate sound scheduling were introduced.

Swipe hit-testing retains the same inner-cell intersections and ordering but restricts candidates to the movement segment's bounds and avoids temporary axis-pair allocations. Actual mark edits already notify the provider, so their redundant explicit setState was removed. The board reuses unchanged cell widgets and region palettes, invalidating on marks, hints, reactions, patterns, reduced motion, enabled state, locale or a new puzzle. Its cell cache is limited to the current board (at most 100 cells), clears on puzzle replacement/disposal, and isolates cell repaints. Audio disposal waits for existing cache preparation before releasing its original output; playback policy, gains and assets are unchanged.

Validation on 2026-11-19: host tests exercise 840 rapid taps and 140 swipe strokes over all sizes 4–10, including motion, pause/resume, persistence and disposal. Tests also verify tile reuse and invalidation of patterns and translated semantics. The full suite passes 153 tests and analysis is clean.

An isolated `com.example.novadoku.perfcheck` installation on a V2420 / Android 16 exercised the real app renderer and original effects with in-memory progress, music off and haptics off. Both debug and profile runs produced the expected 520 edits from 120 taps and 40 ten-cell swipes, retaining the fixed Nova and all budgets. Profile recorded 716 frames: build p95 5.355 ms, raster p95 16.118 ms; 30 frames exceeded 16.667 ms on either thread. Debug build p95 was 40.998 ms and raster p95 14.898 ms, so debug stress did not sustain 60 FPS. Profile process RSS rose from 294,588,416 to 311,709,696 bytes; that short run is not a long-term leak test.

No release/production build was created. Release performance, cold-start timing, prolonged thermal/battery and memory behavior, real file-storage pressure, concurrent music and perceived audio latency are unverified. The source Android configuration and pre-existing debug artifact were restored after testing. The phone disconnected before uninstalling the isolated test package; the user requested finishing without phone cleanup. The normal app installation and saved progress were not used by the harness.

## Gameplay reference-motion update (2026-11-19)

The supplied 35.5-second reference video was reviewed, including the restart sequence at approximately 24.3–24.9 seconds. Only motion is adopted; its artwork, palette, layout, audio and controls are not copied.

- Opening a board runs a 580 ms lower-left to upper-right wave: each cell fades and scales from 12% over 280 ms, with offsets spread over 300 ms regardless of grid size. One shared clock drives the board; tile subtrees and hit-test coordinates stay stable.
- Adding a normal X draws its two rounded strokes and applies a small pop over 170 ms. Removing it fades and shrinks over 90 ms. Each cell retains at most one glyph and one clock; reversing an edit replaces the active animation instead of accumulating outgoing children.
- A newly placed Nova turns from edge-on to face-on, fades in and settles with a subtle bounce over 360 ms. Existing grid art and correct/wrong character clips remain in use; saved/starting Novas do not replay a placement reaction just by loading.
- The main rule card has a brief traveling purple border highlight alongside its existing 1.4-second opening glow. It does not loop or replay on ordinary edits.
- Confirmed reset/retry updates the game immediately, clears cell presentation over 90 ms, then replays the entrance wave. Cancelled reset, hints and ordinary edits do not restart the wave. Input ends any unfinished decorative board entrance so a tap/swipe is never queued behind it.
- Reduced motion immediately presents final cells and marks and skips the highlight, flip, bounce and restart wave. Controllers are stopped/replaced on interruption and disposed with their cells/board. No changes were made to game rules, persistence, gesture recognition, sounds, haptics or other screens.

Host coverage checks all supported entrance sizes, shared-clock/tile reuse, reset budgets and the fixed Nova, interrupted/repeated restarts, immediate input during entrance, drawn X reversal/removal, Nova flip/bounce, reduced motion and ticker disposal. Existing Gameplay stress tests retain the original sound-event and persisted-state assertions. These are functional/rendering checks, not proof of 60 FPS or long-term device performance.

Verification for this update: `flutter analyze` completed with no issues; `flutter test --reporter expanded` passed all 158 tests. Five new motion tests also passed with `--dart-define=ANIMATION_CAPTURE=true`; rendered entrance, X drawing, Nova flip and cleared-restart frames in `build/gameplay_motion/` were inspected. The unchanged Gameplay stress tests exercised 840 rapid taps and 140 swipe strokes across sizes 4–10, along with lifecycle, storage and disposal checks. No production build was created. The earlier device measurements above predate these animation changes; device frame pacing, perceived input latency and prolonged memory/thermal behavior for the new effects remain unverified.


## App presentation audit and refinement (2026-11-19)

The existing app is the reference for this user-approved typography/motion update. It adds no screens or functionality and leaves game state, storage, audio, artwork and layout dimensions intact.

| Surface / interaction | Audit result and final behavior |
| --- | --- |
| Startup / Home | Original drawn wordmark and tagline arrive once with a 420 ms fade and 8 dp settle. No new splash route, startup delay, or artificial loading state. Existing Nova idle/tap clips remain unchanged. |
| Navigation | Home now uses the same custom route presentation as the other screens, rather than a platform default. Screen transitions enter over 260 ms and exit over 200 ms with the existing small fade/slide. |
| Buttons / icon controls | CTAs compress to 98.5% with 2.5% vertical press travel; text actions use restrained compression without travel. Icon controls compress to 94%; compact/grid controls keep their existing motion and do not allocate an extra slide animation. Activation and sound/haptic dispatch still happen on the original events, independent of animation completion. |
| Home level selection | Newly selected indicators have a brief 4.5% settle pulse, retaining their original final size, colors, snapping and unlock restrictions. No change to replay/session handling. |
| Home / Daily background | Only the existing gold/mint dots and Home star drift by at most 3 dp during a finite two-second settling motion. Static gradient/shapes are on a separate repaint boundary. Accents return to their original positions; no ambient infinite loop or motion behind the puzzle board. |
| Daily challenge | Existing play-bow clip, loading state, card interaction and navigation are retained. No duplicate hero entrance is layered over the route and character animation. |
| How to play | Three cards arrive with 70 ms offsets. Mini-grids briefly outline exactly the cells excluded by the center Nova: same row/column, same colored region, or all eight neighbors. The overlay fades completely after 1.8 seconds, preserving the original diagrams at rest. |
| Settings | Existing track color, thumb alignment and localized On/Off motion already work; retained. Settings scales about its lower card anchor, with a live reduced-motion check. Changing settings/language does not replay arrival animations. |
| Hint / mistake | Existing Thinking clip, target outline, warm hint glow, damped shake, red X and heart-loss effects retained. |
| Reset / retry / gameplay | The recently verified staggered cell entrance, X drawing/removal, Nova flip/bounce and rule-card border highlight are unchanged. Budgets, fixed starting Nova and reset confirmation remain owned by the engine/controller. |
| Dialogs / victory | Existing dialog timing, result character reactions and finite confetti/sparkle celebration retained. Lower result dialogs scale around their actual vertical anchor. Reduced motion is checked during presentation, rather than only at modal creation. |

New arrivals retain their clock across locale/provider rebuilds, finish immediately when reduced motion is enabled, remain interactive during motion, and dispose their ticker. The app's existing lifecycle TickerMode still pauses presentation when backgrounded. Finite effects stop scheduling frames when settled; existing character idle loops remain intentional. The new typography and motion use native Flutter APIs with no new runtime dependency. Physical-device frame pacing and long-duration battery/thermal behavior require fresh device measurement; previous device results do not establish performance for this update.


Verification for this refinement: `flutter analyze` reports no issues and the final `flutter test --reporter expanded` run passes all 163 tests, including five added typography/Unicode coverage, live reduced-motion, interactive arrival, press/cancellation and finite-background checks. The existing 158-test suite also passed with `QA_CAPTURE` and `L10N_CAPTURE` enabled. Rendered English surfaces and Hindi Settings/Japanese tutorial were inspected; the real-font layout suite covers all seven locales at phone and enlarged compact sizes, plus existing English tablet coverage. Existing Gameplay stress tests pass unchanged. No device FPS, thermal or long-duration memory measurement was performed and no production build was created.


## Home video-derived idle (2026-11-19)

Home alone uses the transparent animated WebP and first-frame still documented in [NOVA_ART.md](NOVA_ART.md#home-video-replacement-2026-11-19). It loops automatically at the source's approximately 24 fps; the UI does not synthesize extra frames. The existing tap controller, Nova tap sound/haptic event, authored hop reaction and reduced-motion happy still are retained. Repeated tap commands restart the same reaction player rather than adding players. The external controller's existing playback-command semantics remain intact; the Home wrapper returns to its video idle on completion instead of starting the old idle atlas.

Poster and tap/happy clips are warmed without blocking rendering or input. A matching still holds the Home character while the first animated image frame is decoded. Gapless image playback and the existing 180 ms fade handle swaps; outgoing streams/characters are paused during the handoff. Reduced motion selects the single-frame still during idle. Background/inactive lifecycle state, an inherited disabled TickerMode or a covering route pauses Home's central player. App resume and returning to Home resume it. Controller listeners and the lifecycle observer are detached on disposal, and Flutter owns/releases image-stream listeners and codec resources. No manual frame timer, audio output or additional package was introduced. All other screen, background, character and gameplay animation implementations are unchanged.

`test/home_nova_video_test.dart` decodes every frame offline and checks alpha, dimensions, infinite repetition, timing, real changing frames, pixel-identical seam/poster, reduced motion, lifecycle pause/resume, repeated tap reactions, controller replacement and disposal during asset loading. Rendering and frame comparisons use actual Flutter decoded images; they do not establish device frame pacing or long-duration memory behavior.


Verification: `flutter analyze` reports no issues. The full `flutter test --reporter expanded` run passed all 171 tests. After the final framing adjustment, the focused playback/rendering run passed all 14 Home-video and UI-audit tests again. The rendered Home screen was compared with its pre-change capture to align the visible character height/paw baseline while retaining every other layout element. Flutter decoded all 119 frames with alpha, under 0.85 MiB per decoded canvas, correct 4,957 ms infinite-loop timing and identical first/final/poster pixels. Real-pixel animation, paused-frame stability, reduced-motion stills, rapid reactions and teardown checks passed. Physical-device frame pacing, perceived cold-start latency and prolonged memory behavior are not verified. No production build was created.

## Home queued jump reaction (2026-11-19)

This update supersedes the tap/handoff and image-stream implementation described in the preceding Home-video entry. The existing idle WebP and poster bytes, character holder, idle framing, Home layout and all other character players remain unchanged.

Home primes both transparent WebP codecs (first and next frame) before starting motion. An accepted tap queues one reaction while idle finishes its current cycle. Then all 119 jump frames play once, including their final frame duration, followed by idle frame zero. Extra taps while pending/playing are ignored, including duplicate tap feedback; the first tap retains the existing sound/haptic event. There is no crossfade, blank intermediary or normal-handoff asset reload. The larger jump canvas is aligned using the original source-camera coordinates, preserving standing scale and paw baseline with unclipped upward motion.

A single frame-duration timer drives incremental native decoding at the source's approximately 24 fps. Only the character image subtree updates; each codec explicitly retains current/next images rather than a predecoded frame list. Native decoder buffers still contribute memory. Images, pending decode results, codecs, timer, controller listener and lifecycle listener are released on teardown. Covered routes, disabled TickerMode and inactive app states pause playback without skipping the pending reaction. Reduced motion cancels pending/playing motion, uses the existing idle poster and static happy tap expression, and safely primes the jump again for future playback.

Verification: flutter analyze completed with no issues; flutter test --reporter expanded passed all 174 tests. Ten additional UI-audit/capture tests passed. Tests verify every jump frame and duration, alpha, finite metadata, idle-boundary queueing, repeated taps/feedback, first-frame restart, lifecycle pauses, reduced motion, controller replacement and disposal. Actual Home peak-jump and idle captures were reviewed: no clipped Nova or detached watermark; idle capture differences from the prior player were confined to Nova's animated face. Idle/poster SHA-256 hashes remain unchanged. Physical-device frame pacing, cold-start latency and prolonged memory behavior remain unverified. No production build was created.

### Home timing refinement

Home idle now plays at 1.15x and the complete jump at 1.20x. An accepted tap immediately accelerates the remaining idle frames toward a 300 ms handoff; when the cycle is already nearly complete, it finishes sooner rather than slowing down. No source sections are skipped. Idle restarts at frame zero and 1.15x after the jump. Existing assets, layout, tap gating, feedback, reduced motion and lifecycle behavior remain unchanged. The 200-400 ms handoff is a target dependent on native decoding and device scheduling, not a guaranteed device latency.

## Shared Gameplay alpha loop (2026-11-19)

All board-cell Novas, including the fixed starting Nova, use the video-derived transparent loop recorded in NOVA_ART.md. The silhouette indicator and all non-board artwork are untouched. Existing markFraction, centered cell layout and responsive constraints are retained; a 0.92 paint scale compensates for the new crop's smaller transparent margins to retain the prior visible portrait height.

A Gameplay-only scope owns one native Flutter animated-image stream and publishes its current image to portrait-only listeners. All cells share that image and decoder rather than decoding independently or retaining 119 predecoded images. A matching first-frame poster covers initial loading and reduced motion. A stream keep-alive preserves the decoder while listeners are detached for inactive lifecycle, covered routes, disabled TickerMode or reduced motion. Teardown removes the listener, releases its image handle and stream keep-alive, and disposes the lifecycle observer and notifier. Flutter's bounded image cache retains ownership of cached resources.

Correct placements retain the existing 360 ms flip and subtle bounce, with four brief purple/gold glints driven by the same reveal controller. Existing reaction feedback is acknowledged after the reveal without starting a second character player. Completion adds one finite 900 ms soft board-edge glow; it never changes the silhouette tab, blocks input or replays on reset. Reduced motion suppresses reveal sparkles and completion glow. Existing incorrect-cell shake, gestures, sound/haptic events, game state and persistence remain unchanged.

The source plays at approximately 24 fps; rendering is not claimed to synthesize 60 unique character frames per second. Device frame pacing, perceived cold-load latency and prolonged memory behavior require physical-device verification. No production build was created.

Verification: flutter analyze reports no issues. All 53 focused Gameplay playback, motion, interaction and UI-audit tests passed. Tests decoded all 119 frames, verified transparent edges and identical loop endpoints, confirmed ten portraits share one changing image, and exercised lifecycle/reduced-motion/disposal behavior and grid sizes 4-10. The rendered phone board was visually inspected with the new portrait loaded; cell alignment and the unchanged silhouette tab were retained.

## Try Again transparent loop (2026-11-20)

TryAgainNova replaces only the failed outcome's NovaCharacter slot. The slot dimensions, centering, art-panel gradient, copy, actions and every other screen/character remain unchanged. It uses the existing native transparent animated-WebP approach, a matching warmed poster, gapless playback and incremental frame decoding at the source's approximately 24 fps. It does not allocate a list of 119 decoded images or introduce a video player dependency. Reduced motion uses the poster.

Inherited TickerMode, route visibility and app lifecycle pause playback. The lifecycle listener is disposed with the widget; Flutter Image detaches/releases its image-stream listeners and image handles when the dialog closes, with cached resources remaining under Flutter's bounded image cache. Neither source audio nor new sound effects are played. Physical-device frame pacing, cold-load latency and long-duration memory behavior remain unverified. No production build was created.

Verification: flutter analyze completed with no issues; all 48 focused playback, Gameplay/dialog interaction and UI-audit tests passed. Every converted frame was decoded to check transparent edges, dimensions, timing and identical endpoints. Real playback, lifecycle pauses, reduced motion and disposal were tested. Phone, compact and tablet dialog captures were rendered; the phone Try Again capture was visually checked for complete ears/paws/tail, transparency and unchanged dialog layout.

### Try Again timing refinement (2026-11-20)

Try Again now uses a timing-only image provider that divides each decoded frame duration by 1.15. Its separate cache key prevents timing from affecting other players. Native frame pixels, order, repetition count and disposal ownership are unchanged; synchronous asset-key resolution preserves the displayed frame through lifecycle rebuilds. The existing square slot, centering, fit, poster, alpha and source assets are untouched. Focused tests verify 35-37 ms frame advancement versus the original 41-42 ms holds, safe bounds across all frames, matching seam, lifecycle pause, reduced motion and disposal. Device frame pacing remains unverified. No production build was created.

## Level Complete transparent loop (2026-11-20)

The existing Try Again result player and timing-only codec adapter are reused as ResultNovaLoop/ResultNovaImage under shared/characters. TryAgainNova remains a small wrapper selecting its original assets, dimensions and debug label; its playback behavior is unchanged. LevelCompleteNova selects the new completion loop and matching poster within the existing centered square character slot.

Both result loops divide each decoded frame duration by exactly 1.15, retain all frames and source repeat metadata, and use native incremental image decoding with separate asset/speed cache keys. A matching warmed poster, gapless playback, reduced-motion still, route/TickerMode/lifecycle pauses and native image-stream disposal are preserved. First/final pixels match across the loop seam. No other character player is migrated.

Level Complete's surrounding panel, accents, celebration/confetti effects, copy, buttons, navigation, audio events and game state are unchanged. Physical-device frame pacing, perceived cold-load latency and long-duration memory behavior remain unverified. No production build was created.

Verification: flutter analyze completed with no issues. All 50 focused result-loop, Gameplay/dialog interaction and UI-audit tests passed. Both result loops were checked for real changing frames, precise 1.15x first-frame timing, transparent edges across all 119 frames, unchanged canvas size, matching endpoints, lifecycle pause/resume, reduced motion and disposal. Compact/phone/tablet dialogs were rendered; the phone completion capture was visually reviewed for centering, complete source artwork and unchanged accents/layout. Existing progression, retry, sound-event and rapid-input checks passed.

## Daily Challenge transparent loop (2026-11-20)

DailyNova reuses the existing ResultNovaLoop/ResultNovaImage implementation at exactly 1.15x, selecting only Daily-specific loop/poster assets. The Daily screen's square responsive character size calculation, centered placement and localized character semantics remain unchanged, along with all surrounding UI, navigation, gameplay, audio and other character players.

The shared player retains all source frames, native incremental decoding, independent asset/speed cache keys, gapless image playback, a matching warmed poster, reduced-motion still, route/TickerMode/lifecycle pauses and native stream/image disposal. No additional ticker, controller, video player dependency or fully decoded frame list is introduced. The original video already clips the tail at its left edge; NOVA_ART.md records the evidence and source correction required. No additional app-level clipping is introduced.

Physical-device frame pacing, cold-load latency and long-duration memory behavior remain unverified. No production build was created.

Verification: flutter analyze completed with no issues. All 61 focused shared-loop, responsive Daily/tutorial layout, Gameplay interaction and UI-audit tests passed. Coverage includes 1.15x frame timing, all 119 frames and transparent padded boundaries, matching seam, changing pixels, lifecycle pauses, reduced motion, teardown, daily/campaign independence and responsive sizing. The rendered phone Daily screen was reviewed. These tests establish no additional output-canvas clipping; they do not repair or validate away the confirmed source-level tail truncation.

## How to Play transparent loop (2026-11-20)

TutorialNova reuses the existing ResultNovaLoop/ResultNovaImage player at exactly 1.15x, with tutorial-specific loop/poster assets. It replaces only the static header portrait within the existing responsive portraitSize square, centered in the same column. Source proportions and a fixed camera registration are retained. Rule-card diagrams, their separate grid portraits, rule animations, arrival motion, typography, controls, navigation and audio remain untouched.

The shared player retains every source frame, native incremental decoding, separate asset/speed cache keys, gapless playback, warmed first-frame poster, reduced-motion still, route/TickerMode/lifecycle pauses and image-stream disposal. No new animation controller, timer, video player or frame list is added. Physical-device frame pacing, cold-load latency and prolonged memory behavior remain unverified. No production build was created.

Verification: flutter analyze completed with no issues. All 27 focused shared-loop, Daily/tutorial layout and UI-audit tests passed. Tests cover all 119 converted frames, alpha boundaries, matching loop endpoints, real 1.15x frame timing, changing pixels, lifecycle pause/resume, reduced motion and disposal. Responsive sizing and the three unchanged rule demonstrations passed. Phone/compact/tablet surfaces were rendered; the phone tutorial capture was visually checked for centered, complete mascot framing and unchanged surrounding content.

## Daily source replacement (2026-11-20)

Daily Challenge's original video was removed and its two generated assets replaced in place using the new daily challenges.webm source, after confirming those derivatives are referenced only by the Daily player and validation tests. The existing DailyNova/ResultNovaLoop implementation, fixed responsive size, 1.15x timing, semantics, center registration, alpha rendering, reduced-motion behavior, lifecycle pause and disposal are unchanged. The new motion union is normalized to the same overall character scale and center with fixed transparent padding. NOVA_ART.md contains the current conversion command and source details.

The replacement source still cuts the tail at its left edge in frames 60 and 61. This is a source-art limitation, with no added container clipping; complete tail visibility remains dependent on a corrected export. No other screen, layout, character asset, animation, audio or gameplay behavior changed. Device frame pacing, cold-load latency and long-duration memory behavior remain unverified. No production build was created.

Verification: flutter analyze completed with no issues; all 27 focused shared-loop, responsive layout and UI-audit tests passed. The new Daily derivative retains 119 frames, transparent padded boundaries, matching loop endpoints and 1.15x frame timing; lifecycle, reduced motion and teardown checks passed. The rendered phone Daily screen was reviewed. The removed source is absent and has no remaining references in app code, tests, pubspec or documentation. Source-level tail cropping in two frames remains explicitly unresolved.

## Gameplay Hint sheet confirmation (2026-11-20)

The round Hint button now uses the existing reference-styled NovaBottomSheet: HINT badge, A little nudge, thinking Nova, localized dynamic explanation, Apply hint and Cancel. Existing sheet entrance/exit timings, scrim, safe insets, rounded surface, typography and reduced-motion behavior are reused. No Nova video player, character asset, sound asset or other animation was modified. The preview target is temporarily highlighted in place under the independent modal. Opening and closing the sheet do not change Gameplay geometry or scroll offset. Application feedback and existing cell/hint/completion effects run only after a confirmed successful hint.

Verification: flutter analyze completed with no issues. All 76 focused Gameplay, UI-audit and localization tests passed after final framing changes. New tests cover sizes 4-10, untouched preview sessions, Cancel/barrier/Back dismissal, repeated open/apply callbacks, stale-session rejection and unchanged correct-Nova fallback/completion. Existing persistence, budgets, original feedback-event and stress checks passed. Actual Hint-button sheets were rendered on phone/compact/tablet and across supported languages; the phone capture was visually compared with the reference. No production build was created.

## Fixed Hint overlay geometry (2026-11-20)

Removed the preview-only spacer, automatic target scrolling and close-time scroll restoration. Hint Preview continues to use the existing root modal bottom-sheet route, dimmed barrier and sheet-only entrance/exit animations. The entire Gameplay layout remains at its existing offset and dimensions, even if a target is covered by the overlay. A scroll hold stops an in-flight drag/fling without changing the current offset and is released on dismissal. Highlighting, dialog design, Apply/Cancel behavior, hint calculations, budgets, guards, sounds and Nova players are unchanged. No production build was created.

Verification: flutter analyze completed with no issues. All 70 Gameplay/UI-audit tests passed. Fifteen new regressions assert exact header, board, corner-cell and control rectangles plus scroll offset/extent during opening, background gestures, Apply/Cancel and closing across sizes 4-10 with normal/reduced motion, including an interrupted background scroll. Existing hint budgets, duplicate/stale guards, Nova fallback, persistence, sound-event and gameplay checks passed. Rendered phone Hint overlay was reviewed with the original Gameplay header/board positions intact.

## Hint Preview transparent portrait (2026-11-20)

HintNova replaces only the sheet's old thinking atlas character. It reuses the existing ResultNovaLoop/ResultNovaImage at exactly 1.15x with a matching warmed poster, gapless playback, native incremental decoding, reduced-motion still, lifecycle/route/TickerMode pauses and normal stream/image disposal. Other video players remain unchanged.

The original 72 dp square header slot and right padding remain unchanged. A centered OverflowBox paints a 92 dp loop inside this slot, with the new tighter asset framing. The resulting visible portrait height is approximately 1.5 times the previous atlas pose, without changing row, title, body, button or sheet bounds. No extra ticker, controller or predecoded frame list is created. Gameplay remains a fixed background beneath the independent modal; hint highlighting, calculations, consumption, application and duplicate guards are unchanged.

Physical-device frame pacing, cold-load latency and prolonged memory behavior remain unverified. No production build was created.

Verification: flutter analyze completed with no issues; all 94 focused shared-playback, Gameplay, UI-audit and localization-surface tests passed. Coverage checks all 119 frames, true alpha boundaries, matching loop endpoints, 1.15x timing, changing frames, lifecycle/reduced motion/disposal, fixed Gameplay geometry across sizes 4-10, and unchanged hint budgets/apply/cancel/duplicate guards. Phone, compact, tablet and multilingual Hint captures were rendered; phone and compact German captures were visually reviewed for complete enlarged portrait framing and separation from text.

## Home profile interactions (2026-11-20)

The profile modal reuses the existing dialog scale/fade entrance and exit and reduced-motion configuration. Tabs, tile selection, checkmarks and confirmed Home avatar changes use short implicit animations with existing timing and press feedback. Frame art is static vector drawing; avatars are prewarmed offline images. No character/video player, source video, original character animation, gameplay animation or sound was modified. Exact Home hero/badge/action geometry during modal/keyboard changes and prior Nova playback/level-selection behavior passed regression tests. See PROFILE_SPEC.md for the 52-test verification record.

## Gameplay cold-load crash correction (2026-11-20)

The supplied device log identified a null-check failure in GameplayNovaPlayback.didChangeDependencies: an AssetImage stream can be returned before asynchronous asset-manifest/key resolution installs its completer. Decoder retention now waits until the completer exists. One temporary listener bridges unresolved loading, including an early pause or reduced-motion change, then detaches once the decoder is retained if playback is inactive. Disposal removes that listener even if loading has not finished. The existing shared decoder, assets, native frame timing, presentation, gameplay and other character players are unchanged.

A delayed AssetBundle regression reproduced the original null-check exception before the correction. After the correction, flutter analyze reported no issues and all 75 combined Gameplay playback/motion/interaction and Splash tests passed. Coverage includes pausing during unresolved loading, cache eviction before resume, closing before load completes, ten shared portraits and 4x4-10x10 interaction stress (120 taps and 20 strokes per size). The Android buffer-allocation/buffer-queue warnings in the log are not established as resolved by host tests; physical-device rendering and driver behavior still require verification. No production build was created.
