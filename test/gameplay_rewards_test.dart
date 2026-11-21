import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/features/gameplay/gameplay_rewards.dart';
import 'package:novadoku/features/gameplay/gameplay_reward_effects.dart';
import 'package:novadoku/features/gameplay/gameplay_controls.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/game_engine/validator/puzzle_validator.dart';
import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:novadoku/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'reduced motion shows static praise briefly and releases its timer',
    (tester) async {
      final notices = ValueNotifier<GameplayNotice?>(null);
      addTearDown(notices.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Center(child: GameplayPraiseOverlay(notices: notices)),
          ),
        ),
      );
      notices.value = (
        title: GameplayPraise.nice,
        subtitle: null,
        strength: 1,
        event: 1,
      );
      await tester.pump();
      expect(find.text('NICE!'), findsNWidgets(2));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('NICE!'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  for (var size = 4; size <= 10; size++) {
    test('player-only streak, almost and flawless finish at size $size', () {
      var game = PuzzleGame.start(
        PuzzleGenerator.generate(size: size, seed: 11).puzzle,
        level: 1,
      );
      final tracker = GameplayRewards()..bind(game.session);
      expect(tracker.combo, 0);
      GameplayNotice? notice;
      for (final (row, column) in game.verifiedPuzzle.columnsByRow.indexed) {
        final cell = (row: row, column: column);
        if (cell == game.session.startingNova) continue;
        final before = game.session;
        game = game.play(cell).game;
        notice = tracker.discovery(
          before,
          game.session,
          cell,
          player: true,
          mistake: false,
        );
        expect(tracker.combo, row + 1);
        if (size - game.session.novasPlaced == 1) {
          expect(notice!.subtitle, GameplayPraise.almost);
        }
        if (game.session.status != PuzzleStatus.completed) {
          expect(notice!.title, GameplayPraise.values[row.clamp(0, 6)]);
        }
      }
      expect(notice!.title, GameplayPraise.perfectClear);
      expect(notice.subtitle, GameplayPraise.flawless);
      expect(game.session.attemptsRemaining, 3);
    });
  }

  test('automatic discoveries, restored marks and undo cannot farm combos', () {
    var game = PuzzleGame.start(
      PuzzleGenerator.generate(size: 6, seed: 11).puzzle,
      level: 30,
    );
    final tracker = GameplayRewards()..bind(game.session);
    final first = (row: 0, column: game.verifiedPuzzle.columnsByRow[0]);
    final before = game.session;
    game = game.play(first).game;
    tracker.discovery(
      before,
      game.session,
      first,
      player: false,
      mistake: false,
    );
    expect(tracker.combo, 0);
    game = game.undo();
    final undone = game.session;
    game = game.play(first).game;
    expect(
      tracker.discovery(
        undone,
        game.session,
        first,
        player: true,
        mistake: false,
      ),
      isNull,
    );
    expect(tracker.combo, 0);
    final second = (row: 1, column: game.verifiedPuzzle.columnsByRow[1]);
    final prior = game.session;
    game = game.play(second).game;
    tracker.discovery(
      prior,
      game.session,
      second,
      player: true,
      mistake: false,
    );
    expect(tracker.combo, 1);
    tracker.discovery(
      game.session,
      game.session,
      first,
      player: true,
      mistake: true,
    );
    expect(tracker.combo, 0);
    final restored = GameplayRewards()..bind(game.session);
    expect(
      restored.discovery(
        prior,
        game.session,
        second,
        player: true,
        mistake: false,
      ),
      isNull,
    );
    tracker.reset();
    expect(tracker.combo, 0);
  });

  test(
    'X rewards require visible logical exclusions, not solution knowledge',
    () {
      var game = PuzzleGame.start(
        PuzzleGenerator.generate(size: 6, seed: 11).puzzle,
        level: 1,
      );
      final tracker = GameplayRewards()..bind(game.session);
      final visible = [game.session.startingNova!];
      final excluded = <CellPosition>[];
      CellPosition? unjustified;
      for (var row = 0; row < 6; row++) {
        for (var column = 0; column < 6; column++) {
          final cell = (row: row, column: column);
          if (cell == game.session.startingNova) continue;
          if (PuzzleValidator.conflict(game.session.puzzle, cell, visible) !=
              null) {
            excluded.add(cell);
          } else if (!game.verifiedPuzzle.isNova(cell)) {
            unjustified = cell;
          }
        }
      }
      expect(unjustified, isNotNull);
      final old = game.session;
      game = game.selectMode(PuzzleInputMode.markX).play(unjustified!).game;
      expect(tracker.deduction(old, game.session, unjustified), isNull);
      for (var i = 0; i < 5; i++) {
        final before = game.session;
        game = game.play(excluded[i]).game;
        final note = tracker.deduction(before, game.session, excluded[i]);
        expect(note?.title, i == 4 ? GameplayPraise.perfect : null);
      }
      final beforeRemoval = game.session;
      game = game.play(excluded.first).game;
      expect(
        tracker.deduction(beforeRemoval, game.session, excluded.first),
        isNull,
      );
      final beforeReAdd = game.session;
      game = game.play(excluded.first).game;
      expect(
        tracker.deduction(beforeReAdd, game.session, excluded.first),
        isNull,
      );
    },
  );

  test('row, column and region milestones require exactly one Nova and resolved cells', () {
    var game = PuzzleGame.start(
      PuzzleGenerator.generate(size: 4, seed: 11).puzzle,
    );
    final tracker = GameplayRewards()..bind(game.session);
    final start = game.session.startingNova!;
    expect(tracker.milestones(game.session), isEmpty);
    for (var column = 0; column < 4; column++) {
      if (column != start.column) {
        game = game.selectMode(PuzzleInputMode.markX).play((
          row: start.row,
          column: column,
        )).game;
      }
    }
    final flash = tracker.milestones(game.session);
    for (var column = 0; column < 4; column++) {
      expect(flash, contains((row: start.row, column: column)));
    }
    expect(tracker.milestones(game.session), isEmpty);
  });

  testWidgets(
    'single overlay replaces messages, ignores input and disposes cleanly',
    (tester) async {
      final notices = ValueNotifier<GameplayNotice?>(null);
      addTearDown(notices.dispose);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Play'),
                  ),
                ),
                Center(child: GameplayPraiseOverlay(notices: notices)),
              ],
            ),
          ),
        ),
      );
      notices.value = (
        title: GameplayPraise.nice,
        subtitle: null,
        strength: 1,
        event: 1,
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('Play'));
      expect(taps, 1);
      notices.value = (
        title: GameplayPraise.great,
        subtitle: null,
        strength: 2,
        event: 2,
      );
      await tester.pump();
      expect(find.text('NICE!'), findsNothing);
      expect(find.text('GREAT!'), findsNWidgets(2));
      notices.value = (
        title: GameplayPraise.clear,
        subtitle: null,
        strength: 1,
        event: 3,
      );
      await tester.pump();
      expect(find.text('CLEAR!'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  for (final language in ['en', 'hi', 'ja', 'fr', 'de', 'ru', 'pt']) {
    testWidgets('controls have no reserved mistake-banner space in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.8)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        GameplayControls(
                          key: const ValueKey('controls'),
                          hints: 3,
                          novaUses: 4,
                          onNova: null,
                          onHint: null,
                          onReset: null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controls = find.byKey(const ValueKey('controls'));
      final row = find
          .descendant(of: controls, matching: find.byType(Row))
          .first;
      expect(tester.getRect(controls).top, tester.getRect(row).top);
      expect(tester.getSize(controls).height, tester.getSize(row).height);
      expect(find.byKey(const ValueKey('mistake banner')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
