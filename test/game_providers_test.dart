import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';

void main() {
  test('a stale double-tap token cannot roll back intervening edits', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(puzzleGameProvider.notifier);
    await controller.startLevel(1);
    final beforeTap = container.read(puzzleGameProvider).game!;
    final target = (
      row: 0,
      column: beforeTap.verifiedPuzzle.columnsByRow.first,
    );
    controller.play(target, mode: PuzzleInputMode.markX);
    final afterTap = container.read(puzzleGameProvider).game!;
    final other = (row: 1, column: 0);
    controller.play(other, mode: PuzzleInputMode.markX);
    controller.playNovaAfterTap(
      target,
      beforeTap: beforeTap,
      afterTap: afterTap,
    );
    final session = container.read(puzzleSessionProvider)!;
    expect(session.marks[target], CellMark.nova);
    expect(session.marks[other], CellMark.cross);
    expect(session.history, hasLength(3));
    expect(session.attemptsRemaining, 3);
  });

  test(
    'native worker starts, previews, restores and advances a level',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(puzzleGameProvider.notifier);

      expect(container.read(puzzleSessionProvider), isNull);
      await controller.startLevel(1);
      final started = container.read(puzzleGameProvider).game!;
      expect(started.session.level, 1);
      expect(container.read(puzzleGameProvider).load.hasError, isFalse);

      final preview = (await controller.previewHint())!;
      expect(container.read(puzzleSessionProvider)!.hintsRemaining, 3);
      controller.cancelHint(preview);
      controller.applyHint(preview);
      expect(container.read(puzzleSessionProvider)!.hintsRemaining, 3);

      await controller.restore(started.session.toJson());
      for (final (row, column) in started.verifiedPuzzle.columnsByRow.indexed) {
        expect(controller.play((row: row, column: column)), isNull);
      }
      expect(
        container.read(puzzleSessionProvider)!.status,
        PuzzleStatus.completed,
      );
      await controller.startNextLevel();
      expect(container.read(puzzleSessionProvider)!.level, 2);
      expect(
        container.read(puzzleSessionProvider)!.status,
        PuzzleStatus.playing,
      );
    },
  );

  test(
    'daily provider and gameplay use the same calendar key on load',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final instant = DateTime.utc(2026, 11, 18, 15);
      final provider = dailyPuzzleProvider(PuzzleCatalog.dayKey(instant));
      container.listen(provider, (_, _) {});
      final generated = await container.read(provider.future);
      final controller = container.read(puzzleGameProvider.notifier);
      await controller.startDaily(instant);
      final daily = container.read(puzzleSessionProvider)!;
      expect(daily.puzzle.toJson(), generated.puzzle.definition.toJson());
      expect(daily.level, isNull);
      expect(daily.dailyDay, PuzzleCatalog.dayKey(instant));
      expect(daily.unlockedLevel, isNull);
      await controller.restore(daily.toJson());
      controller.reset();
      expect(container.read(puzzleSessionProvider)!.dailyDay, daily.dailyDay);
    },
  );

  test(
    'out-of-order loads and failed replacements preserve consistent state',
    () async {
      final worker = _ControlledWork();
      final container = ProviderContainer(
        overrides: [puzzleWorkProvider.overrideWithValue(worker)],
      );
      addTearDown(container.dispose);
      final controller = container.read(puzzleGameProvider.notifier);

      final oldLoad = controller.startLevel(1);
      final newLoad = controller.startLevel(2);
      expect(container.read(puzzleGameProvider).load.isLoading, isTrue);
      worker.levels[2]!.complete(PuzzleCatalog.level(2));
      await newLoad;
      final opened = container.read(puzzleSessionProvider);
      expect(opened?.level, 2);
      worker.levels[1]!.complete(PuzzleCatalog.level(1));
      await oldLoad;
      expect(container.read(puzzleSessionProvider), same(opened));

      final failure = controller.startLevel(3);
      worker.levels[3]!.completeError(StateError('Worker failure'));
      await failure;
      expect(container.read(puzzleGameProvider).load.hasError, isTrue);
      expect(container.read(puzzleSessionProvider), same(opened));
    },
  );

  test('changing the board invalidates an in-flight hint preview', () async {
    final worker = _ControlledWork();
    final container = ProviderContainer(
      overrides: [puzzleWorkProvider.overrideWithValue(worker)],
    );
    addTearDown(container.dispose);
    final controller = container.read(puzzleGameProvider.notifier);
    final loading = controller.startLevel(1);
    final generated = PuzzleCatalog.level(1);
    worker.levels[1]!.complete(generated);
    await loading;

    final pending = controller.previewHint();
    controller.play((row: 0, column: generated.puzzle.columnsByRow[0]));
    worker.hint.complete(worker.hintSource!.previewHint());
    expect(await pending, isNull);
    expect(container.read(puzzleGameProvider).game!.pendingHint, isNull);
    expect(container.read(puzzleSessionProvider)!.hintsRemaining, 3);
  });
}

final class _ControlledWork implements PuzzleWork {
  final levels = <int, Completer<GeneratedPuzzle>>{};
  final hint = Completer<PuzzleGame>();
  PuzzleGame? hintSource;

  @override
  Future<GeneratedPuzzle> level(int number) =>
      levels.putIfAbsent(number, Completer<GeneratedPuzzle>.new).future;

  @override
  Future<PuzzleGame> preview(PuzzleGame game) {
    hintSource = game;
    return hint.future;
  }

  @override
  Future<GeneratedPuzzle> daily(int day) async => PuzzleCatalog.dailyByKey(day);

  @override
  Future<PuzzleGame> restore(Map<String, Object?> snapshot) async =>
      PuzzleGame.restore(snapshot);
}
