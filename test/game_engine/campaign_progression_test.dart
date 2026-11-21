import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/game_engine/difficulty/campaign_difficulty.dart';
import 'package:novadoku/game_engine/difficulty/difficulty_rating.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/game_engine/solver/puzzle_solver.dart';
import 'package:novadoku/game_engine/validator/puzzle_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('224 campaign puzzles progress gently, stay unique and solve without trial branches', () {
    final layouts = <String>{};
    final sizes = <int>{};
    final bands = <DifficultyBand>{};
    final scores = <int>[];
    final turns = <int>[];
    final total = Stopwatch()..start();
    var generationMicros = 0;
    var slowestChapter = 0;
    for (var chapter = 0; chapter < 56; chapter++) {
      final policy = CampaignDifficulty.forChapter(chapter);
      final timer = Stopwatch()..start();
      final pack = PuzzleCatalog.chapter(chapter);
      generationMicros += timer.elapsedMicroseconds;
      if (timer.elapsedMicroseconds > slowestChapter) {
        slowestChapter = timer.elapsedMicroseconds;
      }
      expect(pack, hasLength(4));
      final ordered = pack.map((p) => p.difficulty.score).toList();
      expect(ordered, [...ordered]..sort());
      for (final (entry, generated) in pack.indexed) {
        final level = chapter * 4 + entry + 1;
        final board = generated.puzzle.definition;
        final rating = generated.difficulty;
        expect(board.id, startsWith('campaign-v2-'));
        expect(board.size, policy.size);
        expect(PuzzleValidator.inspect(board), isNull);
        expect(PuzzleSolver.solve(board).count, 1);
        expect(
          layouts.add(generated.layout),
          isTrue,
          reason: 'Repeated level $level',
        );
        expect(policy.accepts(rating), isTrue);
        expect(rating.contradictions, 0);
        expect(rating.searchProofs, 0);
        expect(rating.singles, board.size - 1);
        final complexity = CampaignDifficulty.regionTurns(board);
        expect(complexity, inInclusiveRange(2, policy.maximumRegionTurns));
        final logical = _solveWithoutGuessing(generated.puzzle);
        expect(logical.placed, board.size);
        if (level == 1) {
          expect(board.size, 4);
          expect(rating.score, 0);
          expect(logical.eliminations, 0);
        }
        if (level <= 24) {
          expect(rating.band, DifficultyBand.gentle);
          expect(logical.eliminations, 0);
        }
        if (level >= 193) expect(rating.band, DifficultyBand.expert);
        if (level >= 25 && level <= 28) {
          expect(rating.lockedEliminations, lessThanOrEqualTo(3));
        }
        sizes.add(board.size);
        bands.add(rating.band);
        scores.add(rating.score);
        turns.add(complexity);
      }
    }
    expect(sizes, {4, 5, 6, 7, 8, 9, 10});
    expect(bands, DifficultyBand.values.toSet());
    double mean(Iterable<int> values) =>
        values.reduce((a, b) => a + b) / values.length;
    final stageMeans = [
      mean(scores.take(24)),
      mean(scores.skip(24).take(40)),
      mean(scores.skip(64).take(128)),
      mean(scores.skip(192)),
    ];
    expect(stageMeans, [...stageMeans]..sort());
    expect(mean(turns.skip(192)), greaterThan(mean(turns.take(24))));
    // ignore: avoid_print
    print(
      '224 campaign boards: generation ${(generationMicros / 1000).toStringAsFixed(1)} ms, '
      'slowest chapter ${(slowestChapter / 1000).toStringAsFixed(1)} ms, '
      'including validation ${total.elapsedMilliseconds} ms; stage mean scores $stageMeans',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'chapter boundaries and distant continuous levels are deterministic',
    () {
      for (final level in [
        1,
        8,
        9,
        20,
        21,
        40,
        41,
        64,
        65,
        96,
        97,
        144,
        145,
        193,
        321,
        4001,
        2147483646,
      ]) {
        final chapter = PuzzleCatalog.chapterOf(level);
        final original = PuzzleCatalog.level(level);
        final repeated = PuzzleCatalog.chapter(chapter)[(level - 1) % 4];
        expect(
          repeated.puzzle.definition.toJson(),
          original.puzzle.definition.toJson(),
        );
        expect(repeated.difficulty.score, original.difficulty.score);
        expect(
          _solveWithoutGuessing(original.puzzle).placed,
          original.puzzle.definition.size,
        );
        if (level > 1) {
          final previous = CampaignDifficulty.forChapter(
            PuzzleCatalog.chapterOf(level - 1),
          );
          final current = CampaignDifficulty.forChapter(chapter);
          expect(current.size - previous.size, inInclusiveRange(0, 1));
        }
      }
      expect(() => PuzzleCatalog.level(0), throwsRangeError);
      expect(() => CampaignDifficulty.forChapter(-1), throwsRangeError);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('old active snapshots and completion records restore exactly before next-level flow', () async {
    final old = PuzzleGenerator.generate(size: 7, seed: 2827849).puzzle;
    var game = PuzzleGame.start(old, level: 27);
    game = game.selectMode(PuzzleInputMode.markX).play((
      row: 0,
      column: 0,
    )).game;
    final given = game.session.startingNova!;
    game = game.selectMode(PuzzleInputMode.placeNova).play((
      row: given.row,
      column: (given.column + 1) % 7,
    )).game;
    game = game.useSmartHint().revealNova();
    final snapshot = game.session.toJson();
    final completed = {for (var level = 1; level < 27; level++) level};
    final storage = MemoryProgressStorage();
    final journal = ProgressJournal(storage);
    await journal.write(
      CampaignProgress.key,
      CampaignProgress(
        game: game,
        completed: completed,
        unlockedThrough: 27,
      ).toJson(),
    );
    final work = BackgroundPuzzleWork();
    final restored = await ProgressJournal(storage).read(
      CampaignProgress.key,
      (json) => CampaignProgress.decode(json, work.restore),
    );
    final container = ProviderContainer(
      overrides: [
        campaignRestoreProvider.overrideWithValue(AsyncData(restored)),
        progressJournalProvider.overrideWithValue(journal),
        puzzleWorkProvider.overrideWithValue(work),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(puzzleGameProvider.notifier);
    await controller.resumeCampaign(27);
    expect(container.read(puzzleSessionProvider)!.toJson(), snapshot);
    expect(container.read(puzzleGameProvider).completedLevels, completed);
    expect(container.read(puzzleGameProvider).unlockedThrough, 27);
    expect(container.read(puzzleSessionProvider)!.puzzle.size, 7);
    expect(container.read(puzzleSessionProvider)!.puzzle.id, startsWith('v1-'));
    controller.selectMode(PuzzleInputMode.placeNova);
    for (final (row, column) in old.columnsByRow.indexed) {
      controller.play((row: row, column: column));
    }
    expect(
      container.read(puzzleSessionProvider)!.status,
      PuzzleStatus.completed,
    );
    expect(container.read(puzzleGameProvider).completedLevels, {
      ...completed,
      27,
    });
    await controller.startNextLevel();
    expect(container.read(puzzleSessionProvider)!.level, 28);
    expect(
      container.read(puzzleSessionProvider)!.puzzle.id,
      startsWith('campaign-v2-'),
    );
    expect(container.read(puzzleGameProvider).completedLevels, {
      ...completed,
      27,
    });
    await controller.saveCurrentProgress();
  });

  test(
    'Daily generation retains the original seed, target and version contract',
    () {
      for (final day in [-1, 0, 20776]) {
        final expected = PuzzleGenerator.generate(
          size: 6 + day % 5,
          seed: -1 - (day * 65537 + 197333) % 2147483646,
          targetScore: 18 + (day % 7) * 8,
        );
        final actual = PuzzleCatalog.dailyByKey(day);
        expect(
          actual.puzzle.definition.toJson(),
          expected.puzzle.definition.toJson(),
        );
        expect(actual.difficulty.score, expected.difficulty.score);
        expect(actual.puzzle.definition.id, startsWith('v1-'));
      }
    },
  );
}

/// Independent rule closure: no Deductions, hint engine, search, solution-driven
/// choice, or hypothetical placements. The solution only checks our deductions.
({int placed, int eliminations}) _solveWithoutGuessing(VerifiedPuzzle puzzle) {
  final board = puzzle.definition;
  final n = board.size;
  bool clash(int a, int b) =>
      a != b &&
      (a ~/ n == b ~/ n ||
          a % n == b % n ||
          board.regionIds[a] == board.regionIds[b] ||
          ((a ~/ n - b ~/ n).abs() <= 1 && (a % n - b % n).abs() <= 1));
  final units = [
    for (var row = 0; row < n; row++) [for (var c = 0; c < n; c++) row * n + c],
    for (var col = 0; col < n; col++) [for (var r = 0; r < n; r++) r * n + col],
    for (final region in board.regionIds.toSet())
      [
        for (var i = 0; i < n * n; i++)
          if (board.regionIds[i] == region) i,
      ],
  ];
  final available = {for (var i = 0; i < n * n; i++) i};
  final fixed = <int>{};
  void place(int cell) {
    expect(puzzle.isNova((row: cell ~/ n, column: cell % n)), isTrue);
    fixed.add(cell);
    available.removeWhere((i) => clash(i, cell));
  }

  place((n - 1) * n + puzzle.columnsByRow.last);
  var eliminations = 0;
  for (var step = 0; step < n * n + n && fixed.length < n; step++) {
    var changed = false;
    for (final unit in units) {
      final candidates = unit.where(available.contains).toList();
      expect(candidates, isNotEmpty);
      if (candidates.length == 1 && !fixed.contains(candidates.single)) {
        place(candidates.single);
        changed = true;
        break;
      }
    }
    if (changed) continue;
    for (final unit in units) {
      final candidates = unit.where(available.contains).toList();
      if (candidates.length < 2) continue;
      final excluded = available
          .where(
            (cell) =>
                !fixed.contains(cell) &&
                candidates.every((c) => clash(cell, c)),
          )
          .firstOrNull;
      if (excluded != null) {
        expect(
          puzzle.isNova((row: excluded ~/ n, column: excluded % n)),
          isFalse,
        );
        available.remove(excluded);
        eliminations++;
        changed = true;
        break;
      }
    }
    if (!changed) {
      fail('Level ${board.id} needs a guess or unsupported deduction.');
    }
  }
  return (placed: fixed.length, eliminations: eliminations);
}
