# Gameplay presentation feedback

## Scope

This user-requested refinement affects Gameplay presentation only. It adds no
gameplay rewards, currency, scoring, unlocks or saved fields. Puzzle generation,
solutions, difficulty, attempts, protected red Xs, hints, controls, persistence,
audio and Nova video decoding/playback remain under their existing owners.
The tracker receives immutable sessions and never reads the hidden solution.

## Attribution and feedback

- Starting and restored Novas are seeded as already seen. Direct player
  discoveries advance NICE, GREAT, AWESOME, WONDERFUL, EXCELLENT, INCREDIBLE and
  AMAZING, with the final tier retained for longer streaks. An incorrect Nova
  placement resets the streak. Automatic reveals do not contribute; undo and
  rediscovery cannot award the same cell twice during this screen visit.
- X feedback requires a new normal X excluded by a visible Nova's row, column,
  region or adjacency. A merely solution-correct guess is insufficient. Repeated
  removal/addition of the same X cannot farm messages. Early levels offer praise
  every five such deductions; later/daily levels every nine. Unsupported marks
  interrupt the deduction sequence. No solver or search runs during gestures.
- Row/column/region completion means all its cells are resolved and exactly one
  contains a Nova. New units pulse once using the existing cell highlight system.
  Already resolved units on restore do not replay. The fixed starting Nova alone
  is not treated as a new player milestone.
- ALMOST THERE appears once with one Nova remaining. FLAWLESS requires all three
  attempts remaining. PERFECT CLEAR additionally requires unused hints and Nova
  reveals. Its 650 ms pre-dialog moment runs only on a new completion in normal
  motion; completion, saves and next-level unlocking have already occurred.
  The existing Level Complete dialog and celebration then run unchanged.

## Motion and layout

- A single replaceable, pointer-transparent praise overlay uses existing heading
  fonts, palette gradients, a white outline, short pop/fade and bounded sparkle
  particles. There is no message queue. X praise cannot interrupt active
  discovery/completion feedback. First-ten-level particle strength progresses
  more generously; advanced levels cap the particle intensity lower.
- Existing Nova flip/bounce is retained with a soft glow and six sparkles. The
  matching region icon adds a fade/scale pop. Nova video widgets, assets, speed,
  alpha rendering, lifecycle handling and resource sharing are unchanged.
- A Gameplay-only heart overlay shakes, cracks, splits and scatters seven tiny
  particles over 620 ms before leaving the existing grey endpoint. A second
  mistake additionally draws the same brief effect just above the rejected cell.
  Shared heart widgets on other screens are unchanged.
- The mistake banner reserves its measured translated height, with centered
  wrapping text, 12 dp horizontal/6 dp vertical padding and an 8 dp control gap.
  Its 180 ms fade and 1800 ms dismissal cannot move board/control geometry.
- Reduced motion removes pop, particles, heart effects and pre-dialog delay;
  praise appears briefly as static text. New copy has English, Hindi, Japanese,
  French, German, Russian and Portuguese variants using existing font fallbacks.
- Timers, listeners and finite animation controllers are disposed with their
  owners. Painter clocks update effects without rebuilding the board or video
  player on animation ticks. Feedback is ephemeral and resets on retry/reset or
  a different puzzle; it is deliberately not reconstructed from saved move
  history, whose entries do not identify manual versus automatic placement.

## Verification limits

Host tests cover reward attribution, public-constraint X deductions, undo/reset,
milestones, sizes 4-10, multilingual wrapping at enlarged text sizes, exact
banner geometry, pointer transparency, reduced motion, completion timing,
unchanged video widget state, persistence and disposal. Combo and second-mistake
phone captures are generated under build/gameplay_rewards for visual review.
Physical-device GPU frame timing, battery and long-duration memory behavior
remain unverified. No production build is part of this change.

Executed verification: `flutter analyze` reported no issues; the complete
`flutter test` suite passed all 263 tests. This includes 19 focused policy/effect
tests and real Gameplay regressions for player/automatic attribution, the second
mistake, unchanged board/control rectangles and Nova player state, and the
pre-dialog Perfect Clear timing. The existing 4-10 stress checks, audio tests,
generation/uniqueness checks, navigation, translations and save/restore tests
also passed. Phone combo and second-mistake captures were visually inspected.
