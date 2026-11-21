import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/theme/app_colors.dart';
import 'package:novadoku/features/gameplay/gameplay_board.dart';
import 'package:novadoku/features/gameplay/gameplay_nova.dart';
import 'package:novadoku/features/gameplay/gameplay_region_pattern.dart';
import 'package:novadoku/features/gameplay/gameplay_region_progress.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ten distinct vector masks stay centered and bounded at small and large cell sizes', () async {
    expect(GameplayPattern.values, hasLength(10));
    for (final side in [24, 40, 80]) {
      final masks = <String>{};
      for (final region in NovaRegionTone.values) {
        final recorder = ui.PictureRecorder();
        GameplayPatternPainter(region)
            .paint(Canvas(recorder), Size.square(side.toDouble()));
        final picture = recorder.endRecording();
        final image = await picture.toImage(side, side);
        final data = (await image.toByteData())!;
        final alpha = <int>[];
        var ink = 0;
        for (var y = 0; y < side; y++) {
          for (var x = 0; x < side; x++) {
            final value = data.getUint8((y * side + x) * 4 + 3);
            alpha.add(value);
            if (value > 0) ink++;
            if (x < side * .1 ||
                x > side * .9 ||
                y < side * .1 ||
                y > side * .9) {
              expect(value, 0);
            }
          }
        }
        expect(ink, greaterThan(8), reason: '${region.name} at $side');
        masks.add(alpha.join(','));
        image.dispose();
        picture.dispose();
      }
      expect(
        masks,
        hasLength(10),
        reason: 'Every motif needs its own geometry at $side',
      );
    }
  });

  test('render tone-on-tone motif inventory for visual review', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final region in NovaRegionTone.values) {
      canvas.save();
      canvas.translate((region.index % 5) * 100.0, (region.index ~/ 5) * 100.0);
      final palette = AppColors.regions[region]!;
      final rect = const Rect.fromLTWH(2, 2, 96, 96);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.top, palette.bottom],
          ).createShader(rect),
      );
      GameplayPatternPainter(region).paint(canvas, const Size.square(100));
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(500, 200);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final directory = Directory('build/gameplay_patterns')
      ..createSync(recursive: true);
    File('${directory.path}/motifs.png')
        .writeAsBytesSync(png.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });

  for (var size = 4; size <= 10; size++) {
    testWidgets(
      'pattern toggle and larger Nova preserve board, progress tab and player at $size',
      (tester) async {
        final game = PuzzleGame.start(
          PuzzleGenerator.generate(size: size, seed: 11).puzzle,
        );
        var patterned = false;
        late StateSetter update;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
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
                        showRegionPatterns: patterned,
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
        final playback = tester.state(find.byType(GameplayNovaPlayback));
        final snapshot = game.session.toJson();
        final icons = tester
            .widgetList<GameplayRegionIcon>(find.byType(GameplayRegionIcon))
            .map((w) => (w.region, w.tone, w.completed))
            .toList();
        final cell = tester.widget<NovaGridCell>(
          find.byKey(ValueKey(game.session.startingNova!)),
        );
        expect(cell.markFraction, .99);
        expect(cell.markFraction / .88, closeTo(1.125, .0001));
        final cellRect = tester.getRect(
          find.byKey(ValueKey(game.session.startingNova!)),
        );
        final novaRect = tester.getRect(find.byType(GameplayNovaImage));
        expect(cellRect.contains(novaRect.topLeft), isTrue);
        expect(cellRect.contains(novaRect.bottomRight), isTrue);
        expect(find.byType(GameplayRegionPattern), findsNothing);
        update(() => patterned = true);
        await tester.pumpAndSettle();
        expect(find.byType(GameplayRegionPattern), findsNWidgets(size * size));
        for (final tile in tester.widgetList<NovaGridCell>(
          find.byType(NovaGridCell),
        )) {
          final motif = tile.regionPattern! as GameplayRegionPattern;
          expect(motif.pattern, GameplayPattern.values[tile.region.index]);
        }
        update(() => patterned = false);
        await tester.pumpAndSettle();
        expect(find.byType(GameplayRegionPattern), findsNothing);
        expect(game.session.toJson(), snapshot);
        expect(tester.state(find.byType(GameplayNovaPlayback)), same(playback));
        expect(
          tester
              .widgetList<GameplayRegionIcon>(find.byType(GameplayRegionIcon))
              .map((w) => (w.region, w.tone, w.completed))
              .toList(),
          icons,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
