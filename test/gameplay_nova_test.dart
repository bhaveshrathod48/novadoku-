import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/constants/app_assets.dart';
import 'package:novadoku/features/gameplay/gameplay_nova.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'cold async asset resolution survives rebuild, pause and resume',
    (tester) async {
      final bundle = _DelayedBundle();
      var reduced = false;
      late StateSetter rebuild;
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: StatefulBuilder(
            builder: (context, update) {
              rebuild = update;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: const Directionality(
                  textDirection: TextDirection.ltr,
                  child: GameplayNovaPlayback(
                    child: Center(
                      child: SizedBox.square(
                        dimension: 64,
                        child: GameplayNovaImage(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      rebuild(() => reduced = true);
      await tester.pump();
      expect(tester.takeException(), isNull);
      bundle.ready.complete();
      for (var i = 0; i < 15; i++) {
        await _step(tester);
      }
      expect(tester.takeException(), isNull);
      // Keep the paused decoder alive even if Flutter evicts its cache entry.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      rebuild(() => reduced = false);
      await tester.pump();
      final portraits = find.byWidgetPredicate(
        (w) =>
            w is RawImage && w.debugImageLabel == 'Gameplay Nova shared loop',
      );
      for (var i = 0; i < 100 && portraits.evaluate().isEmpty; i++) {
        await _step(tester);
      }
      expect(portraits, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _step(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'closing board before async asset resolution detaches listeners',
    (tester) async {
      final bundle = _DelayedBundle();
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: const MediaQuery(
            data: MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: GameplayNovaPlayback(child: SizedBox()),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      bundle.ready.complete();
      for (var i = 0; i < 10; i++) {
        await _step(tester);
      }
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    },
  );

  test(
    'Gameplay asset is a compact silent alpha loop with all source frames',
    () async {
      final data = await rootBundle.load(AppAssets.gameplayNovaLoop);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      try {
        expect(codec.frameCount, 119);
        expect(codec.repetitionCount, -1);
        var duration = Duration.zero;
        Uint8List? first;
        Uint8List? last;
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          try {
            expect((frame.image.width, frame.image.height), (188, 224));
            duration += frame.duration;
            final rgba = (await frame.image.toByteData())!;
            final bytes = rgba.buffer.asUint8List(
              rgba.offsetInBytes,
              rgba.lengthInBytes,
            );
            if (i == 0) first = Uint8List.fromList(bytes);
            if (i == 118) last = Uint8List.fromList(bytes);
            // All four canvas edges remain transparent throughout the motion.
            for (var y = 0; y < 224; y++) {
              expect(bytes[(y * 188) * 4 + 3], lessThanOrEqualTo(2));
              expect(bytes[(y * 188 + 187) * 4 + 3], lessThanOrEqualTo(2));
            }
            for (var x = 0; x < 188; x++) {
              expect(bytes[x * 4 + 3], lessThanOrEqualTo(2));
              expect(bytes[(223 * 188 + x) * 4 + 3], lessThanOrEqualTo(2));
            }
          } finally {
            frame.image.dispose();
          }
        }
        expect(duration.inMilliseconds, 4957);
        expect(listEquals(first, last), isTrue);
      } finally {
        codec.dispose();
      }
    },
  );

  testWidgets('ten board portraits share one changing frame and pause safely', (
    tester,
  ) async {
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
              child: GameplayNovaPlayback(
                child: Center(
                  child: Row(
                    children: [
                      for (var i = 0; i < 10; i++)
                        const Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: GameplayNovaImage(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    final portraits = find.byWidgetPredicate(
      (w) => w is RawImage && w.debugImageLabel == 'Gameplay Nova shared loop',
    );
    for (var step = 0; step < 100 && portraits.evaluate().isEmpty; step++) {
      await _step(tester);
    }
    expect(portraits, findsNWidgets(10));
    final first = tester.widget<RawImage>(portraits.first).image!;
    expect(
      tester
          .widgetList<RawImage>(portraits)
          .every((w) => identical(w.image, first)),
      isTrue,
    );
    for (var step = 0; step < 5; step++) {
      await _step(tester);
    }
    expect(
      identical(tester.widget<RawImage>(portraits.first).image, first),
      isFalse,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final held = tester.widget<RawImage>(portraits.first).image;
    for (var step = 0; step < 5; step++) {
      await _step(tester);
    }
    expect(tester.widget<RawImage>(portraits.first).image, same(held));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    rebuild(() => reduced = true);
    await tester.pump();
    expect(portraits, findsNothing);
    rebuild(() => reduced = false);
    await tester.pump();
    expect(portraits, findsNWidgets(10));
    await tester.pumpWidget(const SizedBox());
    await _step(tester);
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
}

class _DelayedBundle extends CachingAssetBundle {
  final ready = Completer<void>();

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') await ready.future;
    return rootBundle.load(key);
  }
}

Future<void> _step(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await tester.pump(const Duration(milliseconds: 50));
}
