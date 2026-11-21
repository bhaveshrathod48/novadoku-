# Gameplay engine

## Rules

Every row, column, and orthogonally connected region contains exactly one Nova. Novas cannot touch, including diagonally. Boards have 4–10 rows and columns and exactly one solution. A session starts with three attempts. A wrong Nova placement spends one attempt. Exhausting the attempts fails the puzzle. Placing every Nova completes the puzzle and makes the next campaign level available.

## Phase 02 implementation

| Area | Implementation |
| --- | --- |
| Board validation | `PuzzleValidator` checks size, region count, connectivity, and solution rules. `PuzzleSolver.verify` produces the verified puzzle required to start a session. |
| Solver | Precomputes peer masks for rows, columns, regions, and touching cells. It propagates exact-one constraints, branches on a unit with the fewest candidates, and stops at two solutions for uniqueness checks. |
| Generation | Uses a seeded random stream, a legal non-touching placement, and connected frontier growth. The fallback transfers cells from a larger region only while the regions remain connected and uniqueness holds. Sampling and transfer passes are bounded. |
| Repetition | Layout keys normalize region names, rotations, and reflections. The generator accepts layout exclusions. Campaign chapters exclude those equivalents as they build. |
| Difficulty | Measures forced placements, locked-candidate eliminations, propagation contradictions, and search-backed proofs. The strongest required technique and the number of deductions determine the score. |
| Hints | Uses visible Nova constraints first, then forced placements, locked candidates, and contradictions. Each hint supplies a zero-based target, action, machine-readable rule, and English explanation with one-based coordinates. |
| State | `PuzzleGame` transitions create immutable snapshots and report mistake reasons separately. `PuzzleSession` exposes the mark map, reversible edit history, mode, budgets, completion, and next campaign level. |

## Engine decisions

- The Gameplay toolbar now provides four Nova reveals and three automatic hints per run. Nova reveals place one remaining verified solution cell. A smart hint marks up to four empty cells excluded by visible Nova constraints, prioritizing nearby cells; if none remain, it reveals a Nova using the hint budget. Neither action spends attempts. Undo does not refund either budget. Reset/retry refill both.
- The separate explanation/preview API remains supported for existing consumers. Its default hint budget is three. Opening or cancelling a preview preserves the budget. Applying the current preview spends one hint and creates an undoable edit. Each preview can be applied once.
- X marks are player notes. A successful Nova can replace an X. The hint engine proves deductions from placed Novas and the puzzle's constraints even when notes contain errors.
- New puzzles start with one fixed, solution-derived Nova, without spending attempts or hints or adding undo history. Restored v1 boards retain their original starting state.
- Undo reverses the last committed normal edit, including a hint edit. Incorrect placements spend one attempt and leave a protected red X. Taps, swipes, further placement attempts and undo cannot remove that red X or spend another attempt on it. Undo preserves both budgets.
- Reset starts the same puzzle with fresh budgets and the default input mode, retaining its fixed Nova and clearing the previous run's notes and red Xs. Retry does the same after failure. Completion closes the session to edits.
- Campaign v2 chapters contain four canonical-distinct layouts sorted by difficulty measured from the actual fixed starting Nova. The first 24 newly generated levels require only forced placements; later levels progressively require more visible constraint eliminations. Larger boards receive a gentler reasoning target at introduction. Connected region outlines have a progressively relaxed complexity ceiling. Campaign generation rejects puzzles needing hypothetical placements, contradiction trials or backtracking proofs. Daily generation retains its v1 contract.
- Daily boards use a separate seed derived from the UTC calendar day. The date rollover therefore happens at UTC midnight. Keep the versioned generation algorithm available if future releases change the catalog.

## Integration boundaries

`puzzleGameProvider` owns the engine and load status. `puzzleSessionProvider` exposes the current immutable session, and `dailyPuzzleProvider(day)` loads the generated daily puzzle for a UTC day key. Use `PuzzleController` to select a mode, play, undo, reset, retry, preview or apply hints, and advance from a completed campaign puzzle.

The Flutter adapter passes generation, restore verification, and hint computation to a worker isolate on native targets. It keeps one campaign chapter in memory and publishes results only for the latest still-valid request. Flutter's browser fallback runs the callback on its current event loop. [Flutter compute documentation](https://api.flutter.dev/flutter/foundation/compute.html)

The progress journal uses `PuzzleSession.toJson()` for save and resume. `PuzzleGame.restore` reads schema versions 1, 2 and 3, verifies the board, and replays the committed edit log to rebuild marks, undo, and completion state. Version 2 additionally stores the fixed starting Nova and protected red X cells, validated against the unique solution and spent-attempt budget. Version 3 persists remaining Nova reveals, with bounds 0–4. Earlier sessions receive four uses without changing their marks, attempts, hints or history. The snapshot keeps either the campaign level or the daily UTC key, and stores the emitted board so it can be restored independently of future seed changes. Hint previews are transient. Phase 06 retains one campaign session and the most recently played UTC-day session independently through navigation. Resuming a stored session cancels any transient hint preview. Daily completion leaves the campaign cursor and session unchanged. Phase 08 keeps persistent campaign completion and unlocks together and stores Daily sessions independently by UTC date. [Progress storage](PROGRESS_STORAGE.md)

The approved 6 × 6 board remains the reference for UI placement. See the [UI specification](UI_SPECIFICATION.md#2-gameplay).

## Verification

Run `flutter test test/game_engine/puzzle_generation_test.dart --reporter expanded` to reproduce the generation benchmark. It generates 16 boards at each supported size, checks uniqueness with an independent row-permutation enumerator, verifies shape diversity, and times generation separately from validation. The suite also reports measured difficulty and cold generation time for the first seven four-board chapters. Run `flutter test test/game_engine/campaign_progression_test.dart --reporter expanded` for the v2 campaign curve, independent no-guess logical closure, all size transitions, distant level determinism, legacy-session restoration and next-level checks.


## Campaign v2 progression

This policy applies only when generating a new campaign board. No save schema, campaign unlock/completion record, active session, retry/reset state, Daily seed, Daily difficulty or existing gameplay rule changes. Saved snapshots still restore their emitted board and full edit history, independently of the current catalog. New campaign IDs start with `campaign-v2-`; original generator/Daily IDs remain `v1-`. A finished legacy board advances through the existing controller to the next level in the new schedule.

| Levels | Grid | Reasoning progression |
| --- | --- | --- |
| 1-8 | 4x4 | Beginner introduction; Level 1 has immediate forced moves after the given Nova. |
| 9-20 | 5x5 | More room to practice forced row/column/region deductions. |
| 21-40 | 6x6 | First four levels ease into the larger board; bounded locked-candidate eliminations start at Level 25. |
| 41-64 | 7x7 | Longer combinations of the same visible constraints. |
| 65-96 | 8x8 | Increasing deduction chains and region outline complexity. |
| 97-144 | 9x9 | Harder visible elimination chains; no hypothetical branches. |
| 145 onward | 10x10 | Gentle introduction to the maximum grid, then Expert reasoning workload and a bounded difficulty plateau. From Level 193 every accepted board is in the Expert score band. Continuous level numbering is unchanged. |

`CampaignDifficulty` controls hard score bounds, size and maximum extra region-boundary turns. Rectangles/singletons contribute zero extra turns; winding outlines contribute more. The ceilings increase from 12 (4x4) to 76 (10x10). Shape complexity and logical difficulty are separate checks; a large or winding board alone never qualifies as harder reasoning.

Campaign ratings apply the real starting Nova, then repeatedly allow only singles and locked-candidate/common-peer eliminations. A stuck pass rejects the candidate immediately, without running a speculative proof. Opening pressure and the number of logical exclusions set the score; the locked-elimination scale can reach Expert without guessing. The unchanged legacy rating still supports the original diagnostic techniques for other callers. Bands remain Gentle/Easy below 12, Standard/Medium below 35, Challenging/Hard below 70 and Expert from 70. Scores are engineering estimates of logical workload, not human playtest measurements. Short introductory easing at a size boundary is intentional.

Canonical layout keys normalize region names, rotations and reflections. Every chapter excludes its previously accepted keys; deterministic layout buckets separate neighboring chapters of the same size without regenerating campaign history. The 4x4 and 5x5 introductory stages use a distinct bucket for each chapter, preventing repetition throughout those stages. This is bounded local anti-repetition, not a claim of billions of globally distinct finite-grid layouts.

Candidate searches retain hard policy bounds. They use up to 72 sampled partitions and 96 uniqueness-preserving growth attempts per campaign seed, with at most eight deterministic seed alternatives if a seed exhausts its search. Exhaustion reports a typed error; it never ships an invalid, speculative or harder-than-allowed fallback. The existing native worker isolate and one-chapter cache keep generation independent of widget rendering. The Web compute fallback remains on its event loop as before. No additional runtime dependency or pre-generated solution asset is used.


### Verified results for the refinement

`flutter analyze` completed with no issues. The full `flutter test --reporter expanded` run passed all 167 tests. The new progression suite validated Levels 1-224 across sizes 4-10, with no repeated canonical layouts in that sample, exactly one solution per board, and an independent rule-only solver completing every board from its starting Nova. Mean scores for the tested introductory, medium, hard and expert windows were 3.46, 26.98, 49.08 and 73.72 respectively. Determinism and logical completion were also checked at grid boundaries and distant levels through 2,147,483,646. A real v1 generator snapshot retained its board, edits, attempts, hints, reveal budget, undo history and completion records through journal restoration; finishing it advanced to the new catalog without resetting records. Daily seed/target/version compatibility checks passed.

In the full host test run, generating the 224 campaign boards took 55.565 seconds total (about 248 ms per board); the slowest cold four-board chapter took 3.973 seconds. Native gameplay still generates a chapter in the existing worker isolate, then caches its four levels. These are host test measurements, not device load-time or frame-rate claims. The existing additional 112-board generator benchmark and independent uniqueness checks passed as well. No production build was created. Human beginner-to-expert calibration still requires playtesting.
