import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/game_engine/difficulty/difficulty_rating.dart';
import 'package:novadoku/game_engine/hints/hint_engine.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/solver/puzzle_solver.dart';
import 'package:novadoku/game_engine/validator/puzzle_validator.dart';

final _reference = PuzzleDefinition(
  id: 'reference-layout',
  size: 6,
  regionIds: [
    1,
    1,
    1,
    1,
    2,
    2,
    1,
    1,
    2,
    2,
    2,
    2,
    1,
    3,
    3,
    2,
    4,
    2,
    3,
    3,
    3,
    4,
    4,
    2,
    5,
    5,
    3,
    3,
    4,
    2,
    3,
    3,
    3,
    3,
    6,
    2,
  ],
);

const _nova = (row: 0, column: 2);
const _cross = (row: 0, column: 0);
const _wrong = (row: 0, column: 1);

void main() {
  final verified = PuzzleSolver.verify(_reference);

  test(
    'new 4–10 boards have one solution-derived, budget-free, fixed Nova',
    () {
      for (var size = 4; size <= 10; size++) {
        final puzzle = PuzzleGenerator.generate(
          size: size,
          seed: 709 + size,
        ).puzzle;
        final game = PuzzleGame.start(puzzle);
        final given = game.session.startingNova!;
        expect(puzzle.isNova(given), isTrue);
        expect(game.session.marks, {given: CellMark.nova});
        expect(game.session.history, isEmpty);
        expect(game.session.attemptsRemaining, 3);
        expect(game.session.hintsRemaining, 3);
        expect(game.undo(), same(game));
        expect(game.play(given).game, same(game));
        expect(
          game.selectMode(PuzzleInputMode.markX).play(given).game.session.marks,
          {given: CellMark.nova},
        );
        expect(game.reset().session.startingNova, given);
        expect(
          PuzzleGame.restore(_json(game)).session.toJson(),
          game.session.toJson(),
        );
      }
    },
  );

  test(
    'red X is permanent for its run and survives undo and a save round trip',
    () {
      var game = PuzzleGame.start(verified);
      game = game.selectMode(PuzzleInputMode.markX).play(_wrong).game;
      game = game.selectMode(PuzzleInputMode.placeNova).play(_wrong).game;
      expect(game.session.rejectedCells, {_wrong});
      expect(game.session.attemptsRemaining, 2);
      expect(game.play(_wrong).game, same(game));
      expect(
        game
            .selectMode(PuzzleInputMode.markX)
            .play(_wrong)
            .game
            .session
            .marks[_wrong],
        CellMark.cross,
      );
      game = game.undo();
      expect(game.session.history, isEmpty);
      expect(game.session.marks[_wrong], CellMark.cross);
      final restored = PuzzleGame.restore(_json(game));
      expect(restored.session.rejectedCells, {_wrong});
      expect(restored.session.marks, game.session.marks);
      expect(restored.session.attemptsRemaining, 2);
      final failed = restored
          .selectMode(PuzzleInputMode.placeNova)
          .play((row: 1, column: 2))
          .game
          .play((row: 2, column: 2))
          .game;
      expect(failed.session.status, PuzzleStatus.failed);
      final retry = failed.retry();
      expect(retry.session.marks, {game.session.startingNova!: CellMark.nova});
      expect(retry.session.attemptsRemaining, 3);
      expect(retry.session.rejectedCells, isEmpty);
    },
  );

  test('v1 restores unchanged and invalid protected cells are rejected', () {
    final game = PuzzleGame.start(verified).play(_nova).game;
    final old = {..._json(game), 'version': 1}
      ..remove('startingNova')
      ..remove('rejected');
    final restored = PuzzleGame.restore(old);
    expect(restored.session.startingNova, isNull);
    expect(restored.session.marks, {_nova: CellMark.nova});
    expect(restored.session.history, game.session.history);
    final snapshot = _json(game);
    for (final bad in [
      {
        ...snapshot,
        'startingNova': [0, 0],
      },
      {
        ...snapshot,
        'rejected': [
          [0, 2],
        ],
      },
      {
        ...snapshot,
        'rejected': [
          [-1, 2],
        ],
      },
      {
        ...snapshot,
        'rejected': [
          [0, 1],
        ],
      },
      {
        ...snapshot,
        'attempts': 2,
        'rejected': [
          [0, 1],
          [0, 1],
        ],
      },
    ]) {
      expect(() => PuzzleGame.restore(bad), throwsFormatException);
    }
  });

  test(
    'validates board bounds, cardinality, IDs and orthogonal connectivity',
    () {
      PuzzleDefinition board(
        List<int> regions, {
        int size = 4,
        String id = 'test',
      }) => PuzzleDefinition(id: id, size: size, regionIds: regions);

      final rows = List.generate(16, (index) => index ~/ 4);
      expect(PuzzleValidator.inspect(board(rows)), isNull);
      expect(
        PuzzleValidator.inspect(board(rows, id: ' ')),
        BoardIssue.missingId,
      );
      expect(PuzzleValidator.inspect(board(rows, size: 3)), BoardIssue.size);
      expect(PuzzleValidator.inspect(board(rows, size: 11)), BoardIssue.size);
      expect(
        PuzzleValidator.inspect(board(rows.take(15).toList())),
        BoardIssue.cellCount,
      );
      expect(
        PuzzleValidator.inspect(board([...rows]..[0] = -1)),
        BoardIssue.regionId,
      );
      expect(
        PuzzleValidator.inspect(board([...rows]..[0] = 4)),
        BoardIssue.regionCount,
      );
      final disconnected = board([...rows]..[4] = 3);
      expect(
        PuzzleValidator.inspect(disconnected),
        BoardIssue.disconnectedRegion,
      );
      expect(() => PuzzleSolver.solve(disconnected), throwsFormatException);
    },
  );

  test('distinguishes no, one and multiple solutions', () {
    final stripes = PuzzleDefinition(
      id: 'stripes',
      size: 4,
      regionIds: List.generate(16, (index) => index ~/ 4 + 1),
    );
    final noSolution = PuzzleDefinition(
      id: 'blocked',
      size: 4,
      regionIds: [1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4],
    );

    expect(PuzzleSolver.solve(stripes).count, 2);
    expect(PuzzleValidator.inspect(noSolution), isNull);
    expect(PuzzleSolver.solve(noSolution).count, 0);
    expect(() => PuzzleSolver.verify(stripes), throwsFormatException);
    expect(() => PuzzleSolver.verify(noSolution), throwsFormatException);
    expect(verified.columnsByRow, [2, 5, 1, 3, 0, 4]);
    expect(() => verified.columnsByRow[0] = 0, throwsUnsupportedError);
    expect(() => _reference.regionIds[0] = 9, throwsUnsupportedError);
  });

  test('requires exact coverage and rejects row, column, region and diagonal conflicts', () {
    final placements = [
      for (final (row, column) in verified.columnsByRow.indexed)
        (row: row, column: column),
    ];
    expect(PuzzleValidator.isSolution(_reference, placements), isTrue);
    expect(PuzzleValidator.isSolution(_reference, placements.skip(1)), isFalse);
    expect(
      PuzzleValidator.isSolution(_reference, [...placements, _nova]),
      isFalse,
    );
    expect(
      PuzzleValidator.isSolution(_reference, [
        ...placements.skip(1),
        (row: -1, column: 0),
      ]),
      isFalse,
    );

    final checks = {
      (row: 0, column: 0): MoveIssue.sameRow,
      (row: 1, column: 2): MoveIssue.sameColumn,
      (row: 1, column: 0): MoveIssue.sameRegion,
      (row: 1, column: 3): MoveIssue.touching,
    };
    final game = PuzzleGame.start(verified).play(_nova).game;
    for (final entry in checks.entries) {
      final result = game.play(entry.key);
      expect(result.issue, entry.value);
      expect(result.game.session.attemptsRemaining, 2);
      expect(result.game.session.marks, {
        game.session.startingNova!: CellMark.nova,
        _nova: CellMark.nova,
        entry.key: CellMark.cross,
      });
    }
  });

  test('undo reverts committed marks while attempts survive and retry starts fresh', () {
    final start = PuzzleGame.start(verified, level: 7);
    const outside = (row: -1, column: 1);
    expect(start.play(outside).issue, MoveIssue.outsideBoard);
    expect(start.play(outside).game, same(start));

    final noted = start.selectMode(PuzzleInputMode.markX).play(_cross).game;
    expect(noted.session.marks[_cross], CellMark.cross);
    expect(noted.play(_cross).game.session.marks, {
      start.session.startingNova!: CellMark.nova,
    });
    final played = noted.selectMode(PuzzleInputMode.placeNova).play(_nova).game;
    final missed = played.play(_wrong);
    expect(start.play(_wrong).issue, MoveIssue.wrongCell);
    final undone = missed.game.undo();
    expect(undone.session.attemptsRemaining, 2);
    expect(undone.session.marks, {
      start.session.startingNova!: CellMark.nova,
      _cross: CellMark.cross,
      _wrong: CellMark.cross,
    });
    expect(played.session.marks[_nova], CellMark.nova);
    expect(undone.play(_wrong).game, same(undone));
    expect(() => played.session.marks.clear(), throwsUnsupportedError);
    expect(() => played.session.history.clear(), throwsUnsupportedError);

    final failed = undone.play((row: 1, column: 2)).game.play((
      row: 2,
      column: 2,
    )).game;
    expect(failed.session.status, PuzzleStatus.failed);
    expect(failed.play(_nova).game, same(failed));
    expect(failed.undo(), same(failed));
    expect(failed.previewHint(), same(failed));
    expect(failed.session.unlockedLevel, isNull);
    final retry = failed.retry();
    expect(retry.verifiedPuzzle, same(verified));
    expect(retry.session.level, 7);
    expect(retry.session.attemptsRemaining, 3);
    expect(retry.session.hintsRemaining, 3);
    expect(retry.session.marks, {start.session.startingNova!: CellMark.nova});
    expect(undone.reset().session.history, isEmpty);
  });

  test('marks are notes and completion unlocks the next campaign level', () {
    var game = PuzzleGame.start(verified, level: 3);
    game = game.selectMode(PuzzleInputMode.markX).play(_nova).game;
    game = game.selectMode(PuzzleInputMode.placeNova).play(_nova).game;
    expect(game.undo().session.marks[_nova], CellMark.cross);
    expect(
      game
          .selectMode(PuzzleInputMode.markX)
          .play(_nova)
          .game
          .session
          .marks[_nova],
      CellMark.nova,
    );

    expect(game.session.unlockedLevel, isNull);
    for (final (row, column) in verified.columnsByRow.indexed.skip(1)) {
      game = game.play((row: row, column: column)).game;
    }
    expect(game.session.status, PuzzleStatus.completed);
    expect(game.session.unlockedLevel, 4);
    expect(game.undo(), same(game));
    expect(game.reset(), same(game));
    expect(game.play(_wrong).game, same(game));
    final restored = PuzzleGame.restore(_json(game));
    expect(restored.session.status, PuzzleStatus.completed);
    expect(restored.session.unlockedLevel, 4);
  });

  test('hint preview and cancel preserve hints, apply spends once and undo keeps cost', () {
    // A v1 session must retain its original empty board and hint deductions.
    final game = PuzzleGame.restore({
      ...PuzzleGame.start(verified).session.toJson(),
      'version': 1,
      'history': <Object?>[],
    });
    final opened = game.previewHint();
    final preview = opened.pendingHint!;
    expect(preview.action, HintAction.placeNova);
    expect(preview.rule, HintRule.onlyCandidate);
    expect(preview.explanation, contains('only possible Nova'));
    expect(verified.isNova(preview.target), isTrue);
    expect(opened.session.hintsRemaining, 3);
    expect(opened.session.marks, isEmpty);

    final cancelled = opened.cancelHint(preview);
    expect(cancelled.session.hintsRemaining, 3);
    expect(cancelled.applyHint(preview), same(cancelled));
    final reopened = cancelled.previewHint();
    expect(reopened.applyHint(preview), same(reopened));
    final applied = reopened.applyHint(reopened.pendingHint!);
    expect(applied.session.marks[preview.target], CellMark.nova);
    expect(applied.session.hintsRemaining, 2);
    expect(applied.applyHint(reopened.pendingHint!), same(applied));
    expect(applied.undo().session.hintsRemaining, 2);
    expect(applied.undo().session.marks, isEmpty);

    var exhausted = applied;
    for (var attempt = 0; attempt < 2; attempt++) {
      exhausted = exhausted.previewHint();
      expect(exhausted.pendingHint!.action, HintAction.markX);
      exhausted = exhausted.applyHint(exhausted.pendingHint!);
    }
    expect(exhausted.session.hintsRemaining, 0);
    expect(exhausted.previewHint(), same(exhausted));
    expect(exhausted.reset().session.hintsRemaining, 3);
  });

  test('hints explain visible row, column, region and touching deductions', () {
    final examples = {
      (row: 0, column: 0): (HintRule.row, 'Row 1'),
      (row: 1, column: 2): (HintRule.column, 'Column 3'),
      (row: 1, column: 0): (HintRule.region, 'Region 1'),
      (row: 1, column: 3): (HintRule.touching, 'would touch'),
    };
    for (final entry in examples.entries) {
      final marks = <CellPosition, CellMark>{
        for (var row = 0; row < 6; row++)
          for (var column = 0; column < 6; column++)
            if ((row: row, column: column) != entry.key)
              (row: row, column: column): CellMark.cross,
        _nova: CellMark.nova,
      };
      final hint = HintEngine.suggest(verified, marks)!;
      expect(hint.target, entry.key);
      expect(hint.action, HintAction.markX);
      expect(hint.rule, entry.value.$1);
      expect(hint.explanation, contains(entry.value.$2));
    }
  });

  test(
    'versioned snapshots round-trip without persisting hints or the solution',
    () {
      var game = PuzzleGame.start(verified, level: 3).play(_wrong).game;
      game = game.selectMode(PuzzleInputMode.markX).play(_cross).game;
      game = game.previewHint();
      game = game.applyHint(game.pendingHint!);
      game = game.previewHint();

      final snapshot = _json(game);
      final restored = PuzzleGame.restore(snapshot);
      expect(restored.session.toJson(), snapshot);
      expect(restored.session.marks, game.session.marks);
      expect(restored.session.history, game.session.history);
      expect(restored.session.mode, PuzzleInputMode.markX);
      expect(restored.session.attemptsRemaining, 2);
      expect(restored.session.hintsRemaining, 2);
      expect(restored.pendingHint, isNull);
      expect(snapshot.keys, isNot(contains('solution')));
      expect(restored.undo().session.hintsRemaining, 2);
      expect(restored.undo().session.marks, {
        game.session.startingNova!: CellMark.nova,
        _cross: CellMark.cross,
        _wrong: CellMark.cross,
      });

      for (final bad in <Map<String, Object?>>[
        {...snapshot, 'version': 4},
        {...snapshot, 'mode': 'erase'},
        {...snapshot, 'attempts': 4},
        {...snapshot, 'hints': -1},
        {...snapshot, 'level': 0},
        {
          ...snapshot,
          'history': [
            [0, 0, 'nova'],
          ],
        },
        {
          ...snapshot,
          'history': [
            [-1, 0, 'cross'],
          ],
        },
        {
          ...snapshot,
          'history': [
            [0, 0, null],
          ],
        },
        {
          ...snapshot,
          'puzzle': {
            'id': 'invalid',
            'size': 4,
            'regions': [1],
          },
        },
      ]) {
        expect(() => PuzzleGame.restore(bad), throwsFormatException);
      }
    },
  );

  test('reference difficulty measures its logical deductions', () {
    final rating = PuzzleDifficulty.rate(verified);
    expect(rating.singles, 6);
    expect(rating.score, greaterThanOrEqualTo(0));
  });
}

Map<String, Object?> _json(PuzzleGame game) =>
    jsonDecode(jsonEncode(game.session.toJson())) as Map<String, Object?>;
