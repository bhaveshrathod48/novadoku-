import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/difficulty/campaign_difficulty.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/hints/hint_engine.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/solver/puzzle_solver.dart';
import 'package:novadoku/game_engine/validator/puzzle_validator.dart';

void main() {
  test('generates 112 independently verified, connected, varied puzzles', () {
    final elapsed = Stopwatch()..start();
    var totalGeneration = 0;
    var slowest = 0;
    var generatedCount = 0;
    for (var size = 4; size <= 10; size++) {
      final layouts = <String>{};
      var numberedByAnchorRow = 0;
      var sizeGeneration = 0;
      var sizeSlowest = 0;
      for (var sample = 1; sample <= 16; sample++) {
        final timer = Stopwatch()..start();
        final generated = PuzzleGenerator.generate(
          size: size,
          seed: sample * 8917 + size,
        );
        timer.stop();
        sizeGeneration += timer.elapsedMicroseconds;
        if (timer.elapsedMicroseconds > sizeSlowest) {
          sizeSlowest = timer.elapsedMicroseconds;
        }
        expect(PuzzleValidator.inspect(generated.puzzle.definition), isNull);
        expect(_countIndependently(generated.puzzle.definition), 1);
        expect(
          PuzzleSolver.solve(generated.puzzle.definition).firstColumns,
          generated.puzzle.columnsByRow,
        );
        expect(generated.difficulty.singles, size);
        expect(_hasNonRectangularRegion(generated.puzzle.definition), isTrue);
        expect(layouts.add(generated.layout), isTrue);
        if (generated.puzzle.columnsByRow.indexed.every(
          (entry) =>
              generated.puzzle.definition.regionAt((
                row: entry.$1,
                column: entry.$2,
              )) ==
              entry.$1 + 1,
        )) {
          numberedByAnchorRow++;
        }
        generatedCount++;
      }
      expect(numberedByAnchorRow, lessThan(16));
      totalGeneration += sizeGeneration;
      if (sizeSlowest > slowest) slowest = sizeSlowest;
      // Each size gets the same number of seeds while timing generation only.
      // ignore: avoid_print
      print(
        '${size}x$size: 16 boards, mean ${(sizeGeneration / 16000).toStringAsFixed(2)} ms, '
        'max ${(sizeSlowest / 1000).toStringAsFixed(2)} ms',
      );
    }
    expect(generatedCount, 112);
    expect(elapsed.elapsed, lessThan(const Duration(seconds: 30)));
    // ignore: avoid_print
    print(
      '112 boards: generation total ${(totalGeneration / 1000).toStringAsFixed(2)} ms, '
      'max ${(slowest / 1000).toStringAsFixed(2)} ms, '
      'end-to-end including independent validation ${elapsed.elapsedMilliseconds} ms',
    );
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'seeded puzzles are repeatable and layout exclusions reject rotations',
    () {
      final first = PuzzleGenerator.generate(size: 7, seed: 712);
      final repeated = PuzzleGenerator.generate(size: 7, seed: 712);
      expect(
        repeated.puzzle.definition.toJson(),
        first.puzzle.definition.toJson(),
      );
      expect(repeated.puzzle.columnsByRow, first.puzzle.columnsByRow);
      expect(repeated.difficulty.score, first.difficulty.score);
      final excluded = PuzzleGenerator.generate(
        size: 7,
        seed: 712,
        excludedLayouts: {first.layout},
      );
      expect(excluded.layout, isNot(first.layout));
      expect(excluded.puzzle.definition.id, isNot(first.puzzle.definition.id));

      final original = first.puzzle.definition;
      final rotated = PuzzleDefinition(
        id: 'rotated',
        size: original.size,
        regionIds: [
          for (var row = 0; row < original.size; row++)
            for (var column = 0; column < original.size; column++)
              original.regionIds[(original.size - 1 - column) * original.size +
                          row] *
                      7 +
                  10,
        ],
      );
      expect(PuzzleGenerator.layoutKey(rotated), first.layout);
      expect(PuzzleSolver.solve(rotated).count, 1);
      expect(
        () => PuzzleGenerator.generate(size: 11, seed: 1),
        throwsRangeError,
      );
    },
  );

  test('level chapters introduce sizes gently and order unique boards by difficulty', () {
    final layouts = <String>{};
    final means = <double>[];
    final chapters = <List<GeneratedPuzzle>>[];
    var slowest = 0;
    for (var index = 0; index < 7; index++) {
      final timer = Stopwatch()..start();
      final chapter = PuzzleCatalog.chapter(index);
      timer.stop();
      if (timer.elapsedMicroseconds > slowest) {
        slowest = timer.elapsedMicroseconds;
      }
      chapters.add(chapter);
      expect(chapter.length, PuzzleCatalog.levelsPerChapter);
      for (final level in chapter) {
        expect(layouts.add(level.layout), isTrue);
      }
      final scores = chapter.map((level) => level.difficulty.score).toList();
      expect(scores, [...scores]..sort());
      expect(chapter.map((level) => level.puzzle.definition.size).toSet(), {
        CampaignDifficulty.forChapter(index).size,
      });
      means.add(scores.reduce((a, b) => a + b) / scores.length);
    }
    // Introducing a larger grid intentionally eases its reasoning target.
    expect(
      chapters
          .take(6)
          .expand((c) => c)
          .every((g) => g.difficulty.lockedEliminations == 0),
      isTrue,
    );
    expect(
      chapters.last.every((g) => g.difficulty.lockedEliminations > 0),
      isTrue,
    );
    expect(means.last, greaterThan(means.first));
    final first = chapters.first;
    expect(
      first.last.difficulty.score,
      greaterThan(first.first.difficulty.score),
    );
    // ignore: avoid_print
    print(
      'First seven chapter mean scores: $means, slowest four-board chapter '
      '${(slowest / 1000).toStringAsFixed(2)} ms',
    );
    expect(
      PuzzleCatalog.level(24).puzzle.definition.toJson(),
      chapters[5][3].puzzle.definition.toJson(),
    );
    expect(() => PuzzleCatalog.level(0), throwsRangeError);
  });

  test('daily identity is tied to the UTC calendar date', () {
    final before = DateTime.utc(2026, 11, 18, 0, 0, 0, 1);
    final after = DateTime.utc(2026, 11, 18, 23, 59, 59);
    final next = DateTime.utc(2026, 11, 19);
    final daily = PuzzleCatalog.daily(before);
    expect(PuzzleCatalog.dayKey(before), PuzzleCatalog.dayKey(after));
    expect(
      PuzzleCatalog.daily(after.toLocal()).puzzle.definition.toJson(),
      daily.puzzle.definition.toJson(),
    );
    expect(PuzzleCatalog.daily(next).layout, isNot(daily.layout));
    expect(
      PuzzleCatalog.dayKey(DateTime.utc(1969, 12, 31, 23, 59, 59, 999, 999)),
      -1,
    );
  });

  test('generated boards have sound logical hints through completion', () {
    final usedRules = <HintRule>{};
    for (final size in [4, 7, 10]) {
      for (var seed = 1; seed <= 4; seed++) {
        final puzzle = PuzzleGenerator.generate(
          size: size,
          seed: size + seed * 17,
        ).puzzle;
        final marks = <CellPosition, CellMark>{
          // An X on a real solution cell cannot invalidate a true deduction.
          (row: 0, column: puzzle.columnsByRow[0]): CellMark.cross,
        };
        for (var move = 0; move <= size * size; move++) {
          final hint = HintEngine.suggest(puzzle, marks);
          if (hint == null) break;
          expect(hint.explanation, contains('column'));
          usedRules.add(hint.rule);
          if (hint.action == HintAction.placeNova) {
            expect(puzzle.isNova(hint.target), isTrue);
            marks[hint.target] = CellMark.nova;
          } else {
            expect(puzzle.isNova(hint.target), isFalse);
            expect(marks[hint.target], isNull);
            marks[hint.target] = CellMark.cross;
          }
        }
        expect(
          marks.values.where((mark) => mark == CellMark.nova).length,
          size,
        );
      }
    }
    expect(
      usedRules,
      containsAll([HintRule.onlyCandidate, HintRule.lockedCandidates]),
    );
  });
}

int _countIndependently(PuzzleDefinition puzzle) {
  final columns = <int>{};
  final regions = <int>{};
  var solutions = 0;
  void visit(int row, int previousColumn) {
    if (row == puzzle.size) {
      solutions++;
      return;
    }
    for (var column = 0; column < puzzle.size; column++) {
      if ((column - previousColumn).abs() <= 1 || columns.contains(column)) {
        continue;
      }
      final region = puzzle.regionIds[row * puzzle.size + column];
      if (!regions.add(region)) continue;
      columns.add(column);
      visit(row + 1, column);
      columns.remove(column);
      regions.remove(region);
      if (solutions > 1) return;
    }
  }

  visit(0, -2);
  return solutions;
}

bool _hasNonRectangularRegion(PuzzleDefinition puzzle) {
  for (final region in puzzle.regionIds.toSet()) {
    final rows = <int>{};
    final columns = <int>{};
    var cells = 0;
    for (final (index, value) in puzzle.regionIds.indexed) {
      if (value != region) continue;
      rows.add(index ~/ puzzle.size);
      columns.add(index % puzzle.size);
      cells++;
    }
    if (cells != rows.length * columns.length) return true;
  }
  return false;
}
