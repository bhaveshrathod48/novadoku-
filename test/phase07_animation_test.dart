import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/animations/app_motion.dart';
import 'package:novadoku/core/theme/app_colors.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/widgets/nova_celebration.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';

void main() {
  test('Nova holds poses, interpolates breathing, blinks quickly and returns to rest', () {
    const idle = NovaExpression.idle;
    expect(idle.poseAt(const Duration(milliseconds: 250)).blendStep, 0);
    final inhale = idle.poseAt(const Duration(milliseconds: 745));
    expect((inhale.frame, inhale.next), (0, 1));
    expect(inhale.blendStep, inExclusiveRange(0, NovaExpression.blendSteps));
    expect(idle.poseAt(const Duration(milliseconds: 1280)).blendStep, 0);
    final eyelid = idle.poseAt(const Duration(milliseconds: 1319));
    expect((eyelid.frame, eyelid.next), (1, 2));
    expect(eyelid.blendStep, inExclusiveRange(0, NovaExpression.blendSteps));
    expect(idle.frameAt(const Duration(milliseconds: 1360)), 2);
    expect(
      idle.poseAt(idle.duration - const Duration(milliseconds: 1)).next,
      idle.stillFrame,
    );
    expect(
      NovaExpression.celebration
          .poseAt(NovaExpression.celebration.duration)
          .blendStep,
      0,
    );
  });

  testWidgets(
    'celebration draws pixels once, respects reduced motion and disposes the ticker',
    (tester) async {
      const stage = ValueKey('stage');
      Widget host({bool reduced = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const Center(
          child: RepaintBoundary(
            key: stage,
            child: SizedBox.square(dimension: 170, child: NovaCelebration()),
          ),
        ),
      );
      Future<bool> painted() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(stage),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            for (var index = 3; index < data.lengthInBytes; index += 4) {
              if (data.getUint8(index) > 0) return true;
            }
            return false;
          } finally {
            image.dispose();
          }
        }))!;
      }

      await tester.pumpWidget(host());
      expect(await painted(), isFalse);
      await tester.pump(const Duration(milliseconds: 450));
      expect(await painted(), isTrue);
      await tester.pump(AppMotion.celebration);
      expect(await painted(), isFalse);
      await tester.pumpWidget(host(reduced: true));
      expect(find.byKey(const ValueKey('victory particles')), findsNothing);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 500));
      expect(await painted(), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'a new hint event restarts the glow while reduced motion keeps the outline',
    (tester) async {
      Widget host(int pulse, {bool reduced = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.square(
              dimension: 64,
              child: NovaGridCell(
                region: NovaRegionTone.pink,
                regionLabel: '1',
                semanticLabel: 'Hint on row 1',
                appearance: NovaCellAppearance.hint,
                hintPulse: pulse,
              ),
            ),
          ),
        ),
      );
      Finder glow(int pulse) => find.byKey(ValueKey(pulse));

      await tester.pumpWidget(host(0));
      expect(glow(0), findsOneWidget);
      await tester.pump(AppMotion.hintHighlight);
      await tester.pumpWidget(host(1));
      expect(glow(0), findsNothing);
      expect(glow(1), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pumpWidget(host(1, reduced: true));
      expect(glow(1), findsNothing);
      expect(find.bySemanticsLabel('Hint on row 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
