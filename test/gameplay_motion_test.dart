import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/theme/app_colors.dart';
import 'package:novadoku/features/gameplay/gameplay_board.dart';
import 'package:novadoku/features/gameplay/gameplay_cross.dart';
import 'package:novadoku/features/gameplay/gameplay_motion.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';

void main() {
  test('entrance stays bounded and sequential at every supported size', () {
    for (var size = 4; size <= 10; size++) {
      for (var row = 0; row < size; row++) {
        for (var column = 0; column < size; column++) {
          expect(GameplayMotion.cellProgress(0, row, column, size), 0);
          expect(GameplayMotion.cellProgress(1, row, column, size), 1);
          if (column + 1 < size) {
            expect(
              GameplayMotion.cellProgress(.5, row, column, size),
              greaterThanOrEqualTo(
                GameplayMotion.cellProgress(.5, row, column + 1, size),
              ),
            );
          }
        }
      }
    }
  });

  testWidgets('one entrance clock staggers cells without rebuilding tiles', (
    tester,
  ) async {
    final host = _BoardHost();
    await tester.pumpWidget(host.widget());
    final original = tester.widget<NovaGridCell>(_cell((row: 0, column: 0)));
    final first = _entrance(tester, (row: 5, column: 0));
    final last = _entrance(tester, (row: 0, column: 5));
    expect(first.listenable, same(last.listenable));
    expect(_opacity(tester, first), 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester, first), greaterThan(0));
    expect(_opacity(tester, last), 0);
    await _capture(tester, 'entrance-100ms');
    expect(
      tester.widget<NovaGridCell>(_cell((row: 0, column: 0))),
      same(original),
    );
    await tester.pumpAndSettle();
    expect(_opacity(tester, last), 1);
    await _capture(tester, 'entrance-finished');
    // Unrelated presentation rebuilds do not replay the entrance.
    host.rebuild(() {});
    await tester.pump();
    expect((first.listenable as Animation<double>).value, 1);
    await _dispose(tester);
  });

  testWidgets(
    'restart clears then rebuilds and preserves immediate reset state',
    (tester) async {
      final host = _BoardHost();
      await tester.pumpWidget(host.widget());
      await tester.pumpAndSettle();
      host.mark((row: 0, column: 0));
      await tester.pumpAndSettle();
      host.restart();
      await tester.pump();
      final entrance = _entrance(tester, (row: 5, column: 0));
      expect(host.game.session.marks, {
        host.game.session.startingNova!: CellMark.nova,
      });
      expect(host.game.session.attemptsRemaining, 3);
      expect(host.game.session.hintsRemaining, 3);
      expect(host.game.session.novaUsesRemaining, 4);
      expect(_opacity(tester, entrance), 1);
      await tester.pump(GameplayMotion.clear);
      expect(_opacity(tester, entrance), 0);
      await _capture(tester, 'restart-cleared');
      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacity(tester, entrance), greaterThan(0));
      await tester.pumpAndSettle();
      expect(_opacity(tester, entrance), 1);
      // Repeated restarts replace the active clock, rather than stacking motion.
      host.restart();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      host.restart();
      await tester.pump();
      expect((entrance.listenable as Animation<double>).value, 0);
      await _dispose(tester);
    },
  );

  testWidgets(
    'tap interrupts entrance; X draws, exits quickly and reverses cleanly',
    (tester) async {
      final host = _BoardHost();
      const target = (row: 0, column: 0);
      await tester.pumpWidget(host.widget());
      await tester.tap(_cell(target));
      expect(host.game.session.marks[target], CellMark.cross);
      await tester.pump();
      expect(
        (_entrance(tester, target).listenable as Animation<double>).value,
        1,
      );
      await tester.pump(const Duration(milliseconds: 45));
      GameplayCross cross() => tester.widget<GameplayCross>(
        find.descendant(
          of: _cell(target),
          matching: find.byType(GameplayCross),
        ),
      );
      expect(cross().color, AppColors.surface);
      expect(cross().progress, inExclusiveRange(0, 1));
      await _capture(tester, 'cross-drawing');
      // Remove during drawing, then reverse again before the outgoing mark ends.
      host.mark(target);
      await tester.pump();
      expect(host.game.session.marks[target], isNull);
      await tester.pump(const Duration(milliseconds: 30));
      expect(
        find.descendant(
          of: _cell(target),
          matching: find.byType(GameplayCross),
        ),
        findsOneWidget,
      );
      host.mark(target);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(cross().progress, 1);
      host.mark(target);
      await tester.pump();
      await tester.pump(
        GameplayMotion.markOut + const Duration(milliseconds: 1),
      );
      expect(
        find.descendant(
          of: _cell(target),
          matching: find.byType(GameplayCross),
        ),
        findsNothing,
      );
      await _dispose(tester);
    },
  );

  testWidgets(
    'Nova flips and bounces; reduced motion finishes active effects',
    (tester) async {
      final host = _BoardHost();
      await tester.pumpWidget(host.widget());
      await tester.pumpAndSettle();
      final correct = (
        row: 0,
        column: host.game.verifiedPuzzle.columnsByRow.first,
      );
      host.rebuild(() {
        host.game = host.game
            .selectMode(PuzzleInputMode.placeNova)
            .play(correct)
            .game;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final transforms = tester.widgetList<Transform>(
        find.descendant(of: _cell(correct), matching: find.byType(Transform)),
      );
      expect(
        transforms.any((t) => t.transform.entry(0, 2).abs() > .01),
        isTrue,
      );
      await _capture(tester, 'nova-flipping');
      await tester.pump(const Duration(milliseconds: 180));
      expect(
        tester
            .widgetList<Transform>(
              find.descendant(
                of: _cell(correct),
                matching: find.byType(Transform),
              ),
            )
            .any((t) => t.transform.entry(1, 1) > 1),
        isTrue,
      );
      host.rebuild(() => host.reduced = true);
      await tester.pumpAndSettle();
      host.restart();
      await tester.pump();
      expect(
        (_entrance(tester, correct).listenable as Animation<double>).value,
        1,
      );
      host.mark((row: 1, column: 0));
      await tester.pump();
      final cross = tester.widget<GameplayCross>(
        find.descendant(
          of: _cell((row: 1, column: 0)),
          matching: find.byType(GameplayCross),
        ),
      );
      expect(cross.progress, 1);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await _dispose(tester);
    },
  );
}

Finder _cell(CellPosition cell) => find.byKey(ValueKey(cell));
GameplayCellEntrance _entrance(WidgetTester tester, CellPosition cell) =>
    tester.widget<GameplayCellEntrance>(
      find.ancestor(
        of: _cell(cell),
        matching: find.byType(GameplayCellEntrance),
      ),
    );
double _opacity(WidgetTester tester, GameplayCellEntrance entrance) => tester
    .widget<Opacity>(
      find
          .descendant(
            of: find.byWidget(entrance),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  expect(tester.binding.transientCallbackCount, 0);
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('ANIMATION_CAPTURE')) return;
  await tester.runAsync(
    () => precacheImage(
      NovaArtwork.grid.image,
      tester.element(find.byType(GameplayBoard)),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .descendant(
          of: find.byType(GameplayBoard),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final folder = Directory('build/gameplay_motion')
        ..createSync(recursive: true);
      await File('${folder.path}/$name.png')
          .writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _BoardHost {
  PuzzleGame game = PuzzleGame.start(
    PuzzleGenerator.generate(size: 6, seed: 1).puzzle,
  );
  late StateSetter rebuild;
  int epoch = 0;
  bool reduced = false;

  void mark(CellPosition cell) => rebuild(() {
    game = game.selectMode(PuzzleInputMode.markX).play(cell).game;
  });
  void restart() => rebuild(() {
    game = game.reset();
    epoch++;
  });

  Widget widget() => MaterialApp(
    home: StatefulBuilder(
      builder: (context, setState) {
        rebuild = setState;
        return MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: SizedBox(
              width: 354,
              child: GameplayBoard(
                session: game.session,
                restartEpoch: epoch,
                onCellPressed: mark,
                onNovaPressed: (_) {},
                onSwipeCell: (cell, _) => mark(cell),
                onReactionCompleted: (_) {},
              ),
            ),
          ),
        );
      },
    ),
  );
}
