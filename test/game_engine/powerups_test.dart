import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/game_engine/validator/puzzle_validator.dart';

void main() {
  final puzzle = PuzzleGenerator.generate(size: 6, seed: 804).puzzle;
  Map<String, Object?> snapshot(PuzzleGame game) =>
      jsonDecode(jsonEncode(game.session.toJson())) as Map<String, Object?>;

  test(
    'Nova reveals spend only their own four-use budget and undo cannot refund',
    () {
      var game = PuzzleGame.start(puzzle);
      for (var remaining = 3; remaining >= 0; remaining--) {
        final before = game.session;
        game = game.revealNova();
        expect(game.session.novasPlaced, before.novasPlaced + 1);
        expect(game.session.novaUsesRemaining, remaining);
        expect(game.session.hintsRemaining, 3);
        expect(game.session.attemptsRemaining, 3);
        for (final entry in game.session.marks.entries) {
          if (entry.value == CellMark.nova) {
            expect(puzzle.isNova(entry.key), isTrue);
          }
        }
      }
      expect(game.revealNova(), same(game));
      final restored = PuzzleGame.restore(snapshot(game));
      expect(restored.session.toJson(), game.session.toJson());
      game = restored.undo();
      expect(game.session.novaUsesRemaining, 0);
      expect(game.revealNova(), same(game));
      final reset = game.reset();
      expect(reset.session.novaUsesRemaining, 4);
      expect(reset.session.hintsRemaining, 3);
      expect(reset.session.marks, {game.session.startingNova!: CellMark.nova});
    },
  );

  test(
    'smart hints prove one bounded group from placed Novas and charge once',
    () {
      var game = PuzzleGame.start(puzzle);
      for (var remaining = 2; remaining >= 0; remaining--) {
        final before = game.session;
        game = game.useSmartHint();
        final added = game.session.marks.entries
            .where((e) => before.marks[e.key] != e.value)
            .toList();
        expect(added.length, inInclusiveRange(1, 4));
        final placed = before.marks.entries
            .where((e) => e.value == CellMark.nova)
            .map((e) => e.key);
        for (final entry in added) {
          if (entry.value == CellMark.cross) {
            expect(puzzle.isNova(entry.key), isFalse);
            expect(
              PuzzleValidator.conflict(puzzle.definition, entry.key, placed),
              isNotNull,
            );
          } else {
            expect(puzzle.isNova(entry.key), isTrue);
          }
        }
        expect(game.session.hintsRemaining, remaining);
        expect(game.session.novaUsesRemaining, 4);
        expect(game.session.attemptsRemaining, 3);
      }
      expect(game.useSmartHint(), same(game));
      expect(
        PuzzleGame.restore(snapshot(game)).session.marks,
        game.session.marks,
      );
    },
  );

  test(
    'when no new X deductions remain Hint reveals Nova despite incorrect notes',
    () {
      var game = PuzzleGame.start(puzzle).selectMode(PuzzleInputMode.markX);
      for (var row = 0; row < 6; row++) {
        for (var column = 0; column < 6; column++) {
          game = game.play((row: row, column: column)).game;
        }
      }
      final before = game.session;
      game = game.useSmartHint();
      expect(game.session.novasPlaced, before.novasPlaced + 1);
      expect(game.session.hintsRemaining, 2);
      expect(game.session.novaUsesRemaining, 4);
      expect(game.session.attemptsRemaining, 3);
    },
  );

  test(
    'old snapshots gain a fresh Nova counter without changing board or budgets',
    () {
      final game = PuzzleGame.start(puzzle).useSmartHint();
      for (final version in [1, 2]) {
        final old = {...snapshot(game), 'version': version}..remove('novaUses');
        final restored = PuzzleGame.restore(old);
        expect(restored.session.novaUsesRemaining, 4);
        expect(restored.session.hintsRemaining, game.session.hintsRemaining);
        expect(restored.session.history, game.session.history);
        if (version == 2) expect(restored.session.marks, game.session.marks);
      }
      for (final value in [-1, 5, null, '4']) {
        expect(
          () => PuzzleGame.restore({...snapshot(game), 'novaUses': value}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'completion by a power-up is terminal and unlocks the campaign level',
    () {
      var game = PuzzleGame.start(puzzle, level: 2);
      for (final (row, column) in puzzle.columnsByRow.indexed.skip(1)) {
        game = game.play((row: row, column: column)).game;
      }
      expect(game.session.status, PuzzleStatus.playing);
      game = game.revealNova();
      expect(game.session.status, PuzzleStatus.completed);
      expect(game.session.unlockedLevel, 3);
      expect(game.revealNova(), same(game));
      expect(game.useSmartHint(), same(game));
      expect(
        PuzzleGame.restore(snapshot(game)).session.status,
        PuzzleStatus.completed,
      );
    },
  );
}
