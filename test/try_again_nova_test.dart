import 'package:novadoku/features/gameplay/hint_nova.dart';
import 'package:novadoku/features/tutorial/tutorial_nova.dart';
import 'package:novadoku/features/daily_challenge/daily_nova.dart';
import 'package:novadoku/features/gameplay/level_complete_nova.dart';
import 'package:novadoku/shared/characters/result_nova_loop.dart';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/constants/app_assets.dart';
import 'package:novadoku/features/gameplay/try_again_nova.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final config in [
    (
      asset: AppAssets.tryAgainNovaLoop,
      label: 'Try Again Nova 1.15x',
      character: const TryAgainNova(size: 216),
    ),
    (
      asset: AppAssets.levelCompleteNovaLoop,
      label: 'Level Complete Nova 1.15x',
      character: const LevelCompleteNova(size: 216),
    ),
    (
      asset: AppAssets.dailyNovaLoop,
      label: 'Daily Nova 1.15x',
      character: const DailyNova(size: 216),
    ),
    (
      asset: AppAssets.tutorialNovaLoop,
      label: 'Tutorial Nova 1.15x',
      character: const TutorialNova(size: 216),
    ),
    (
      asset: AppAssets.hintNovaLoop,
      label: 'Hint Nova 1.15x',
      character: const HintNova(size: 216),
    ),
  ]) {
    group(config.label, () {
      test(
        'retry loop retains all frames, alpha, safe framing and identical seam',
        () async {
          final data = await rootBundle.load(config.asset);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          Uint8List? first;
          Uint8List? last;
          var changing = false;
          var duration = Duration.zero;
          try {
            expect(codec.frameCount, 119);
            expect(codec.repetitionCount, -1);
            for (var i = 0; i < 119; i++) {
              final frame = await codec.getNextFrame();
              try {
                expect((frame.image.width, frame.image.height), (384, 384));
                final rgba = (await frame.image.toByteData())!;
                final bytes = rgba.buffer.asUint8List(
                  rgba.offsetInBytes,
                  rgba.lengthInBytes,
                );
                first ??= Uint8List.fromList(bytes);
                if (i == 60) changing = !listEquals(first, bytes);
                if (i == 118) last = Uint8List.fromList(bytes);
                for (var j = 0; j < 384; j++) {
                  for (final pixel in [
                    j,
                    383 * 384 + j,
                    j * 384,
                    j * 384 + 383,
                  ]) {
                    expect(bytes[pixel * 4 + 3], lessThanOrEqualTo(2));
                  }
                }
                duration += frame.duration;
              } finally {
                frame.image.dispose();
              }
            }
            expect(changing, isTrue);
            expect(duration.inMilliseconds, 4957);
            expect(listEquals(first, last), isTrue);
          } finally {
            codec.dispose();
          }
        },
      );

      testWidgets(
        'retry plays real frames, pauses, respects reduced motion and disposes',
        (tester) async {
          addTearDown(
            () => tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            ),
          );
          var reduced = false;
          late StateSetter rebuild;
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, update) {
                rebuild = update;
                return MediaQuery(
                  data: MediaQueryData(disableAnimations: reduced),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Center(child: config.character),
                  ),
                );
              },
            ),
          );
          expect(
            tester.getSize(find.byType(config.character.runtimeType)),
            const Size(216, 216),
          );
          final animation = find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is ResultNovaImage &&
                (w.image as ResultNovaImage).asset == config.asset,
          );
          RawImage? raw() {
            final target = find.descendant(
              of: animation,
              matching: find.byWidgetPredicate(
                (w) => w is RawImage && w.debugImageLabel == config.label,
              ),
            );
            return target.evaluate().isEmpty
                ? null
                : tester.widget<RawImage>(target.first);
          }

          for (var i = 0; i < 100 && raw()?.image == null; i++) {
            await _step(tester);
          }
          final first = raw()!.image!;
          // The original 41-42 ms first frame must hold for 35 ms, then advance
          // by 37 ms at 1.15x. Allow native prefetch to finish outside the fake
          // clock; decoder load must not change the asserted playback cadence.
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pump(const Duration(milliseconds: 35));
          expect(raw()!.image, same(first));
          await tester.pump(const Duration(milliseconds: 2));
          expect(raw()!.image, isNot(same(first)));
          for (var i = 0; i < 5; i++) {
            await _step(tester);
          }
          expect(raw()!.image, isNot(same(first)));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          await tester.pump();
          final held = raw()!.image;
          for (var i = 0; i < 5; i++) {
            await _step(tester);
          }
          expect(raw()!.image, same(held));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          rebuild(() => reduced = true);
          await tester.pump();
          expect(animation, findsNothing);
          rebuild(() => reduced = false);
          await tester.pump();
          expect(animation, findsOneWidget);
          await tester.pumpWidget(const SizedBox());
          await _step(tester);
          expect(tester.takeException(), isNull);
          expect(tester.binding.transientCallbackCount, 0);
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        },
      );
    });
  }
}

Future<void> _step(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await tester.pump(const Duration(milliseconds: 50));
}
