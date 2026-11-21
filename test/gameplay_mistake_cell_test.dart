import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/theme/app_colors.dart';
import 'package:novadoku/features/gameplay/gameplay_cross.dart';
import 'package:novadoku/features/gameplay/gameplay_mistake_cell.dart';
import 'package:novadoku/features/gameplay/gameplay_region_pattern.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';
import 'package:novadoku/features/gameplay/gameplay_board.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';

Widget cell(int? event, {bool reduced = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        key: const ValueKey('capture'),
        child: SizedBox.square(
          dimension: 100,
          child: GameplayMistakeCell(
            event: event,
            builder: (reveal) => NovaGridCell(
              key: const ValueKey('wrong cell'),
              region: NovaRegionTone.mint,
              regionLabel: '2',
              semanticLabel: 'Incorrect placement',
              showRegionLabel: false,
              appearance: NovaCellAppearance.mistake,
              restoreRegionOnMistake: true,
              showRegionPattern: true,
              regionPattern: const GameplayRegionPattern(
                region: NovaRegionTone.mint,
              ),
              markReveal: reveal,
              markFraction: .82,
              mark: GameplayCross(color: AppColors.error, animation: reveal),
            ),
          ),
        ),
      ),
    ),
  ),
);

GameplayMistakePainter painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((widget) => widget.painter)
    .whereType<GameplayMistakePainter>()
    .single;

void main() {
  test(
    'heart stage durations are exact and X draws only after all four stages',
    () {
      expect(GameplayMistakeCell.appearanceMs, 250);
      expect(GameplayMistakeCell.holdMs, 200);
      expect(GameplayMistakeCell.crackMs, 350);
      expect(GameplayMistakeCell.breakMs, 500);
      expect(GameplayMistakeCell.heartEndMs, 1300);
      expect(GameplayMistakeCell.duration.inMilliseconds, 1470);
    },
  );
  testWidgets('wrong X uses exactly the normal X stroke geometry and easing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
    final context = tester.element(find.byType(Directionality));
    await tester.runAsync(() async {
      for (final t in [0.0, .2, .5, .8, 1.0]) {
        final masks = <List<int>>[];
        for (final cross in [
          GameplayCross(
            color: AppColors.surface,
            progress: Curves.easeOutCubic.transform(t),
          ),
          GameplayCross(
            color: AppColors.error,
            animation: AlwaysStoppedAnimation(t),
          ),
        ]) {
          final recorder = ui.PictureRecorder();
          final widget = cross.build(context) as CustomPaint;
          widget.painter!.paint(Canvas(recorder), const Size.square(80));
          final picture = recorder.endRecording();
          final image = await picture.toImage(80, 80);
          final raw = (await image.toByteData())!;
          masks.add([
            for (var i = 3; i < raw.lengthInBytes; i += 4) raw.getUint8(i),
          ]);
          image.dispose();
          picture.dispose();
        }
        expect(masks[0], masks[1], reason: 'Stroke geometry must match at $t');
      }
    });
  });

  for (var size = 4; size <= 10; size++) {
    testWidgets(
      'all three mistakes animate independently with immediate attempts at size $size',
      (tester) async {
        var game = PuzzleGame.start(
          PuzzleGenerator.generate(size: size, seed: 11).puzzle,
        );
        GameplayShake? shake;
        late StateSetter update;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return Center(
                    child: SizedBox(
                      width: 320,
                      child: GameplayBoard(
                        session: game.session,
                        shake: shake,
                        onCellPressed: (_) {},
                        onNovaPressed: (_) {},
                        onSwipeCell: (_, _) {},
                        onReactionCompleted: (_) {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final wrong = [
          for (var row = 0; row < size; row++)
            for (var column = 0; column < size; column++)
              (row: row, column: column),
        ].where((cell) => !game.verifiedPuzzle.isNova(cell)).take(3).toList();
        Animation<double>? firstClock;
        for (var i = 0; i < 3; i++) {
          update(() {
            game = game.play(wrong[i]).game;
            shake = (cell: wrong[i], event: i + 1);
          });
          await tester.pump();
          expect(game.session.attemptsRemaining, 2 - i);
          expect(game.session.rejectedCells, contains(wrong[i]));
          final clocks = tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((w) => w.painter)
              .whereType<GameplayMistakePainter>()
              .map((p) => p.clock)
              .toList();
          expect(clocks, hasLength(i + 1));
          firstClock ??= clocks.first;
          await tester.pump(const Duration(milliseconds: 100));
          expect(firstClock.value, closeTo((i + 1) * 100 / 1470, .001));
        }
        final snapshot = game.session.toJson();
        await tester.pump(const Duration(milliseconds: 1400));
        expect(game.session.toJson(), snapshot);
        expect(find.byType(GameplayMistakeCell), findsNWidgets(3));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets(
    'rose heart cracks and splits before matching rose X draws on the restored region',
    (tester) async {
      await tester.pumpWidget(cell(1));
      final tile = tester.widget<NovaGridCell>(
        find.byKey(const ValueKey('wrong cell')),
      );
      expect(tile.markReveal!.value, 0);
      final samples = <int, List<int>>{};
      var elapsed = 0;
      for (final ms in [300, 440, 600, 1000, 1380, 1500]) {
        await tester.pump(Duration(milliseconds: ms - elapsed));
        elapsed = ms;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final raw = (await image.toByteData())!;
          samples[ms] = [
            for (var channel = 0; channel < 3; channel++)
              raw.getUint8((50 * 100 + 50) * 4 + channel),
          ];
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final dir = Directory('build/mistake_effect')
            ..createSync(recursive: true);
          File('${dir.path}/$ms.png')
              .writeAsBytesSync(png.buffer.asUint8List());
          image.dispose();
        });
        if (ms < 1300) expect(tile.markReveal!.value, 0);
        if (ms == 1380) {
          final cross = tester.widget<GameplayCross>(
            find.byType(GameplayCross),
          );
          expect(cross.animation!.value, inExclusiveRange(0, 1));
        }
      }
      expect(samples[300], [154, 54, 88]);
      expect(samples[440], samples[300]);
      expect(samples[1000]![0], greaterThan(180));
      expect(samples[1000]![1], greaterThan(150));
      expect(samples[1500], [154, 54, 88]);
      expect(tile.markReveal!.value, 1);
      expect(painter(tester).clock.value, 1);
      expect(find.byType(GameplayRegionPattern), findsOneWidget);
      final decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.regions[NovaRegionTone.mint]!.edge);
      expect(border.top.width, 1);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new gestures and dependency rebuilds do not truncate or replay the effect',
    (tester) async {
      var event = 1 as int?;
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return cell(event);
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final clock = painter(tester).clock;
      update(() => event = null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter(tester).clock, same(clock));
      expect(clock.value, closeTo(200 / 1470, .001));
      await tester.pump(const Duration(milliseconds: 1400));
      update(() {});
      await tester.pump();
      expect(clock.value, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'restored rejected cells are final and reduced motion skips entrance: $reduced',
      (tester) async {
        await tester.pumpWidget(cell(reduced ? 1 : null, reduced: reduced));
        expect(painter(tester).clock.value, 1);
        expect(
          tester
              .widget<NovaGridCell>(find.byKey(const ValueKey('wrong cell')))
              .markReveal!
              .value,
          1,
        );
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reduced motion during playback and disposal release the clock', (
    tester,
  ) async {
    var reduced = false;
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return cell(1, reduced: reduced);
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    update(() => reduced = true);
    await tester.pump();
    expect(painter(tester).clock.value, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
