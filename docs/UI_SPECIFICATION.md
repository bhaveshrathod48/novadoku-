# UI specification

## Approved Settings refinement (2026-11-20)

The in-app Reduced Motion row is removed. Music, Sound effects, Haptics,
Region patterns, Language and How to play keep their existing controls and
behavior. No other screen layout, typography, artwork or animation timing
changes as part of the navigation/haptic audit. The older reference inventory
below records the original design; this explicit refinement supersedes that
single Settings row.

## Gameplay region motifs and cell Nova size (2026-11-20)

The latest user-approved Gameplay refinement replaces its old repeated texture
with one centered vector symbol per cell. Palette order maps to Paw Print, Cat
Face, Fishbone, Stars, Yarn Ball, Butterfly, Leaves, Hearts, Moon and Nova
Bandana. Each symbol uses the existing region edge color at 64% opacity and a
68% square drawing area, preserving tone-on-tone contrast and responsive bounds.
The Region Patterns preference still controls visibility; Off renders the
original plain cells. Decorations remain behind marks and are excluded from
pointer handling and semantics. A feature-specific decoration slot preserves
the shared grid widget's prior fallback for any non-Gameplay consumers.

Only Nova's Gameplay cell mark fraction grows from 0.88 to 0.99 (12.5%). The
existing inner video inset, aspect ratio, alpha, native playback and reveal
effects remain intact. X fractions, region logic and silhouette indicator are
unchanged. No character or raster asset was generated or edited.

Verification: flutter analyze reported no issues; all 126 focused Gameplay,
pattern, motion, Nova, reward, audio and shared-widget tests passed. Checks cover
ten distinct bounded vector masks at 24/40/80 px, pattern toggling across sizes
4-10, enlarged Nova containment, unchanged player state and silhouette data.
The rendered motif inventory in build/gameplay_patterns/motifs.png was visually
reviewed. No production build was created.

[Approved reference sheet](reference/novadoku-ui.jpg)

The reference sheet contains all ten approved designs. The individual attachments show the same ten designs, including a paired crop for Level complete and Leave puzzle. Copy below is transcribed from the screenshots. Dimensions and weights are implementation estimates from the roughly 293 × 634 px panels on the sheet, normalized to a 390 dp portrait canvas. The screenshots govern whenever an estimate differs. Time, connectivity marks, and the home indicator belong to the operating system.

## Design system

| Element | Reference observation and Phase 01 token |
| --- | --- |
| Backgrounds | Home and Daily use a diagonal lavender-to-blue-to-blush field (`#ECE8FF`, `#E3E8FE`, `#F6EBFB`). Large overlapping translucent circles, a right-side violet shape, a lower-left blush shape, and sparse gold/mint dots and stars frame the character. Gameplay and How to play are nearly flat pale lavender (`#F4F2FC`) with a large, slightly darker pale arc at upper right. |
| Primary and secondary | Purple accent `#7138DC`. Primary CTAs shade from lighter violet at the top/left toward deeper purple at the bottom/right, with a small lavender bottom edge. Secondary CTAs are white with a quiet lavender outline. Text actions use purple. Disabled surfaces and tracks are muted lilac-gray. |
| Text and fonts | Near-black plum `#242038` and muted plum `#635D74`. The wordmark is dense, heavy, rounded lowercase lettering with tight tracking and a small purple accent dot. Large headlines and dialog titles are rounded and heavy. Supporting text is clean and shorter in line height. The current playful typography uses DynaPuff 600/700 at 95% width for headings and Nunito Sans 600/700 for supporting copy and controls, with offline Noto fallbacks. The wordmark art and accent detail belong to Home. |
| Type scale | Logo 54 dp with −1.5 tracking. Display 38 dp with −0.6 tracking and 1.04 line height. Screen and dialog titles 30 dp. Sections and buttons 16 dp and bold. Body 16 dp, supporting descriptions 14 dp, labels and mistakes 12 dp, badges 11 dp, region numbers 10 dp. Gameplay's `NOVADOKU` eyebrow uses uppercase and 1.8 dp tracking. |
| Page rhythm | About 24 dp horizontal screen gutter, reduced to 16 dp for narrow windows. Brand/utility bar sits below the top system inset. Typical adjacent controls are 6–16 dp apart and sections 16–32 dp apart. Main content remains centered at wide sizes and wraps or scrolls when space is constrained. |
| Buttons, cards, icons | Primary button min height 56 dp and about 19 dp radius. Outlined buttons min height 52 dp. Cards use 22 dp corners, white fill and optional soft shadow. Icon actions use 48 dp rounded-square targets with 24 dp purple line icons. Inputs use the distinct white, lilac, mint and warm-yellow tints shown. |
| Attempts | Three small solid pink hearts (`#EC7CAA`) in a white pill, reduced to pale lilac as attempts are used. Short supporting label centered under the pill. |
| Grid | Six columns and rows in the reference, on a white container with rounded corners and soft depth. Cells are square and tightly spaced (roughly 4 dp), around 9 dp radius, with a subtle bevel/shade. Region number at top-left, Nova artwork or X centered. Use one visual palette per region. Hint preview outlines the target in white. Mistake cell uses a pale inset and wine-colored outline and exclamation mark. |
| Region palette | Pink `#F88AAD`, mint `#66DAC7`, peach `#FFB576`, yellow `#FFDF7C`, blue `#7DC4FC`, purple `#BDA2F1`. Each palette defines a lighter top and darker edge. Region numbers provide a cue independent of color. |
| Dialog and sheet | White rounded rectangles at roughly 90% screen width and 28 dp radius. Insets about 16–20 dp, content padding about 24 dp. Around 40% deep-plum barrier (`#66242038`). Small gray-lilac centered handle on the floating hint sheet. Keep the original screen visible through the barrier. |
| Character | Center the full-body hero above the Home level steps or on the Daily hero field, with a diffuse oval ground shadow where shown. Use the approved head/pose variants in grid, tutorial, hint and result slots. Establish scale by available width and preserve the art's intrinsic aspect ratio. |
| Depth and status | Short button edge and low-opacity plum surface shadows. Mint with deep teal text for success. Pale pink with wine text for a mistake. Pale lilac for selection or lavender badges. Warm yellow for hint/star icon tiles. |

Implementation lives in `AppColors`, `AppTokens`, `AppType`, `AppTheme`, and `AppMotion`. The placement below applies when the relevant screens are built.

## Vertical landmarks

These percentages describe the screenshot panels from top to bottom, including the status and navigation areas. Runtime layout bases its usable space on the actual safe areas.

| Screen or overlay | Reference landmarks |
| --- | --- |
| Home | Utility row around 10%, wordmark 18%, hero around 41%, main CTA 74%, daily card 85%. |
| Gameplay and mistake feedback | Attempts around 18%, board from 33% to 75%, mode selector around 80%, bottom actions around 89%. Mistake adds a slim banner above those actions. |
| Settings | Dialog spans about 15% to 94% of the window. |
| Hint preview | Sheet spans about 55% to 97%, with the top of the board behind the barrier. |
| Try again and Level complete | Matching outer dialog bounds from about 21% to 87%. |
| Leave puzzle | Compact dialog from about 35% to 76%. |
| Daily challenge | Headline around 19%, hero around 45%, today's puzzle card around 65%, CTA around 77%, and rules around 89%. |
| How to play | Character around 20%, headline around 32%, rule cards from 39% to 79%, CTA around 88%. |

## 1. Home

- Header. Nova head in a white rounded square on the left, white pill `LEVEL 3` in the center, and purple outlined settings icon on the right.
- Branding. `novadoku` over `A little puzzle. A little joy.` Centered above the full-body standing Nova. Pastel shapes sit behind the character.
- Centered progression row `2`, `3`, `4`, joined by a thin line. Mint completed step, strong purple active step, white upcoming step. `Your next little challenge` below.
- Wide purple `Play level 3`, then a white card with a yellow star tile, `Daily challenge`, `A fresh puzzle every day`, and right chevron.
- Centered text action `How to play` near the bottom.

Phase 04 traces the wordmark from the approved Home crop and draws it as a Flutter path. The app uses the reference gradient, outlined settings gear, oval ground shadow, and the Phase 03 standing, idle, and hop artwork. The illustrated level numbers above are a reference example. The app starts at Level 1 with the first position empty until a previous level exists. Type and controls respect system insets, and short layouts can scroll. With reduced motion, a Nova tap shows the happy pose as a still.

## 2. Gameplay

- Back arrow and settings gear flank an eyebrow `NOVADOKU` above `Level 3`. Three pink hearts and `3 attempts left` below.
- Equal white pills read `Row + column`, `Every region`, `Never touch`.
- Board heading `Find the Novas` left and `1 of 6` right. Sample region IDs by row, left to right

  ```text
  1 1 1 1 2 2
  1 1 2 2 2 2
  1 3 3 2 4 2
  3 3 3 4 4 2
  5 5 3 3 4 2
  3 3 3 3 6 2
  ```

- Sample Nova at row 1, column 3. X marks at row 2, column 2, row 4, column 1, and row 6, column 6.
- Mode selector `Place Nova` and `Mark X`, with the former filled purple.
- Bottom actions `Undo` (curved arrow, white tile), `Hint · 3` (bulb, yellow tile), `Reset` (circular arrow, mint tile).

Phase 05 scales the same board layout to each generated puzzle, using the original six region colors and four companion colors for larger boards. Board labels, counts, and level titles come from the loaded session. A mistake changes the affected tile and adds a banner without shifting the board. Short viewports scroll with the device's safe insets.

## 3. Settings

- Home dimmed behind a tall centered white dialog. Left heading `Settings`, close icon at upper right, subtitle `Make it feel like you.`
- Rows in order. `Music` — `Off`. `Sound effects` — `On`. `Haptics` — `On`. `Reduced motion` — `Off`. `Region patterns` — `Off`. Rows have fine dividers. Switch thumb moves to the right with a purple On track.
- `Language` on the left and `English` with a chevron on the right.
- Purple `How to play` then centered `Your preferences, your pace.`

## 4. Hint preview

- Dim Gameplay and outline the board cell in row 2, column 1. A floating white bottom sheet covers the lower part of the board and toolbar, with the system navigation inset below.
- Handle centered above content. Small `HINT` pill and left-aligned `A little nudge`. Nova head at upper right.
- `Region 1 already has a Nova.` and `Mark row 2, column 1 with an X.`
- Wide purple `Apply hint` and purple text `Cancel`.

## 5. Mistake feedback

- Keep Gameplay visible and change the hearts to two pink and one pale. Label `2 attempts left`.
- In the reference, row 2, column 3 shows a wine-bordered light cell containing `!`. A pale pink banner between mode selector and toolbar says `Same column. Try another square.`
- Keep the Gameplay header, rule pills, `Find the Novas`, `1 of 6`, selector and toolbar labels.

## 6. Try again

- Dim Gameplay with spent hearts. Large lower-centered white dialog.
- Lavender `A FRESH START` pill above a circular pastel art panel with the seated, eyes-closed Nova.
- `One more try?` then `A fresh start. A new perspective.` and `You have got this.`
- Wide purple `Try again`, then centered purple text `Back home`.

## 7. Level complete

- Dim Gameplay behind a large lower-centered white dialog. Mint `PUZZLE COMPLETE` pill, smiling Nova portrait centered in a circular pastel panel with sparse accents.
- `Beautifully done.` then `All 6 Novas found.` and `Your next puzzle is waiting.`
- Wide purple `Next level` then centered purple text `Back home`.

## 8. Leave puzzle

- Dim Gameplay, show a compact lower-centered white dialog over the board.
- `Take a break?` and centered two lines `Your puzzle will be here` / `when you return.`
- Purple `Keep playing` followed by white outlined `Save and leave`.

## 9. Daily challenge

- Pastel hero background. Back arrow and settings gear flank `DAILY PLAY` pill.
- Centered two-line headline `A fresh little` / `challenge.` above crouching Nova with raised tail on overlapping pastel shapes.
- Centered white card with yellow star, `Today’s puzzle` and `Same rules. A new arrangement.`
- Wide purple `Play daily puzzle`. Bottom copy `One Nova per row, column and region.` followed by `No touching, even diagonally.`

## 10. How to play

- Pale background, back arrow left, `HOW TO PLAY` white pill centered. Nova head above the two-line centered headline `Small rules.` / `Bright possibilities.`
- Three stacked white rule cards. Each has a mini-grid left and title plus description right.
  1. `Rows + columns` / `One Nova in every` / `row and column.`
  2. `Every region` / `One Nova in each` / `coloured region.`
  3. `Never touching` / `Keep Novas apart,` / `even diagonally.`
- Near the bottom, wide purple `Let’s play`.

## Phase 06 integration details

### Approved Gameplay interaction update

Gameplay distributes its header, attempts, one rounded rule card with three illustrated sections, a connected progress-tab/board surface and bottom actions through the safe screen height. The board and actions sit slightly higher, without a separate floating indicator card or board shadow. Compact or enlarged-text layouts can scroll. The rule card briefly glows on entry, unless reduced motion is enabled.

A single tap immediately toggles and saves a normal X. The second tap of a double tap replaces that exact provisional edit with a Nova attempt, without extra undo history or an X sound. Swiping selects its mode from the starting cell: empty adds normal X marks, a normal X erases normal Xs, and a protected Nova/red X does not start an editing stroke. Each eligible cell changes at most once per gesture; reversing direction keeps the same mode. Stroke/inner-cell intersection avoids accidentally marking corner-adjacent cells on diagonals. Nova cells and permanent red Xs are protected. Mistakes spend one attempt, leave a red X, and show localized `Try another square.` feedback. Red Xs survive undo and saving; reset/retry clear the previous run's mistakes with fresh budgets. Every new puzzle has one fixed solution-derived Nova, preserved by undo/reset/retry. Older saved boards restore unchanged.

Gameplay normal X marks are large, bold, rounded and white; incorrect Xs remain red. Nova artwork fills more of each cell. Region numbers are visually hidden while internal IDs, patterns and accessibility descriptions remain intact. The connected progress tab has a compact width derived from 4–10 region icons. Icons target 28 dp, up from 24 dp, with responsive shrinking on narrow boards. The centered tab uses the same 30 dp slot calculation to preserve its board connection.

Three circular actions replace the previous toolbar: Nova (four reveals), Hint (three automatic deductions) and Reset. Each reveal places one remaining correct Nova. Hint adds up to four excluded Xs, or reveals a Nova when there are no new X deductions. Counters are saved independently; exhausted controls are disabled. Reset uses a localized confirmation dialog; Cancel leaves the session unchanged, while confirming clears marks/mistakes and restores the fixed given, attempts and both power-up budgets. Existing press, placement, glow, sound and haptic behavior remains in use.

The three mini-grids illustrate region exclusion, row/column exclusion and all eight adjacent cells. Each region has a silhouette tinted with its board palette, replaced by the existing Nova icon on placement. Undo, applied hints and reset derive this progress directly from the session. Other screens and the puzzle constraints remain unchanged.

Hint text and highlights come from the current board. When the sheet would conceal the target, Gameplay scrolls it into the visible area and restores the prior scroll position on dismissal. Result copy uses the current puzzle size, and the next-level action appears only when a campaign level is unlocked. Daily play has its own resumable session. Phase 08 restores it by UTC date and saves campaign and Daily progress independently. Settings applies region patterns to the gameplay grid and offers English or system locale selection.

## Bundled fonts and pending assets

DynaPuff and Nunito Sans are bundled variable fonts distributed under the SIL Open Font License. Both license texts ship with the app and are registered in the license registry. [DynaPuff source](https://github.com/google/fonts/tree/main/ofl/dynapuff) and [Nunito Sans source](https://github.com/google/fonts/tree/main/ofl/nunitosans). The original drawn Home wordmark is unchanged. Legacy Fredoka, Baloo 2 and Nunito source files remain on disk for provenance but are no longer registered or shipped.

Localized copy uses the existing hierarchy and allows wrapping and scrolling when needed. Offline Noto fallbacks cover the supported scripts. The English reference copy above remains the design source. [Localization and font sources](LOCALIZATION.md)

The approved reference sheet remains the visual authority. Phase 03 contains reference-based transparent stills, a grid-sized cutout, and ten pose atlases. Phase 07 bundles the original soundtrack and nine sound cues and draws celebration particles with Flutter. Final launcher artwork remains a production asset. [Nova artwork and source prompts](NOVA_ART.md)


## Approved typography and motion refinement (2026-11-19)

This update uses the existing application as its visual reference, as requested. Layout dimensions, gutters, palette, copy, logo paths, character artwork, controls and game rules are unchanged. Display/tutorial headings use Baloo 2 ExtraBold (800); screen/dialog headings use Bold (700). Supporting descriptions use Nunito SemiBold (600); sections, controls and labels use Bold (700). Font weight is explicit as well as using the variable weight axis, so script fallbacks receive the intended weight. Heading line heights are 1.12-1.14 to give the new fonts room for accents and Indic shaping; supporting text retains 1.3 line height. Existing responsive wrapping and compact-layout scrolling remain in place.

The new Baloo2.ttf is the upstream variable font, SHA-256 `d47a6852548059b1db49a1319d06d499d546c3fa2237cf9eee9c43c8abb025c2`. No runtime font downloads or new packages were added. All seven catalogs are checked against the actual bundled fonts' Unicode character maps, in addition to rendering with the real fonts at phone and enlarged compact sizes.


## Current playful typography (2026-11-19)

The user selected playful, distinctive headings with clean supporting text. DynaPuff replaces Baloo 2: screen/dialog headings use weight 600, and display/tutorial headings use weight 700, with the variable width axis set to 95. This preserves the existing type sizes and layout while adding a more individual, rounded letter shape. Nunito Sans replaces Nunito throughout the theme, descriptions, labels and buttons at weights 600/700. Heading line heights are 1.12-1.16; supporting text keeps 1.3. The original Home wordmark paths, copy, palette, component placement, characters, motion and game behavior are untouched.

DynaPuff supplies the Latin display lettering; existing bundled Noto Sans, Noto Sans Devanagari and Noto Sans JP cover other supported scripts, including Russian, Hindi and Japanese, offline. Font choices and weights remain centralized in AppType; no runtime downloads or new package dependencies are needed. The upstream files are unmodified: DynaPuff.ttf SHA-256 `c3752fc6dd8aaa46a88637f061a9a4e6ab44c02c5f0afd65528b91ae8ff6f948`, NunitoSans.ttf SHA-256 `f934d7142fb4784bf828da485b7dcbd90c0c80d514e9d49a5da0ed3a1ae2491d`. New license texts are bundled and registered at startup.

The existing font-coverage tests now inspect the current files rather than legacy families, and real-font surface tests load DynaPuff/Nunito Sans explicitly. The seven-language and compact/enlarged-text rendering checks passed, including screen/dialog navigation and the existing safe-area layout checks. Home, tutorial and completion screenshots were visually inspected after rendering.

Verification: `flutter analyze` completed with no issues; the full `flutter test --reporter expanded` run passed all 167 tests. The focused real-font/layout run passed 38 tests with QA_CAPTURE/L10N_CAPTURE enabled. No gameplay, progression, animation, audio, saved data, wordmark artwork or component-layout implementation changed in this font-only refresh. No production build was created.

## Authorized Home profile addition (2026-11-20)

The top-left Home tile now opens the reference-inspired Profile modal using the existing purple/lavender palette, typography, rounded surfaces, transitions and interaction feedback. It contains an editable username, framed preview, Avatar/Frame tabs, 4x2 grids, animated selected checks, Confirm and Close. Its independent root overlay preserves Home geometry and does not resize the hero when the keyboard opens. Only the profile card/avatar and level badge receive the requested slight enlargement. All original Nova video implementations remain unchanged. [Profile specification](PROFILE_SPEC.md).

## Profile visual refinement (2026-11-20)

Avatar options now use their supplied per-character pastel backgrounds without permanent borders or frames; only the selected avatar has a selection outline/check. Frame choices are simple rounded colored strokes with a subdued custom Nova paw and only the selected frame has a checkmark. The username has no visible floating label and uses a custom game-style edit glyph. The Home icon combines the saved avatar, its own background and chosen outer frame directly, without the white backing card. Existing Profile layout, saved IDs, central Nova and all unrelated UI remain unchanged. See PROFILE_SPEC.md for colors and verification.
