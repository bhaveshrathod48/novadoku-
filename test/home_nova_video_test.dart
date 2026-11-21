import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/constants/app_assets.dart';
import 'package:novadoku/features/home/home_nova_character.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/characters/nova_character.dart';

const _stage = ValueKey('Home video test');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'jump has 119 transparent frames, full jump headroom and one playback',
    () async {
      final data = await rootBundle.load(AppAssets.homeNovaJump);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      try {
        expect(codec.frameCount, 119);
        expect(codec.repetitionCount, 0);
        Uint8List? first;
        var duration = Duration.zero;
        var peak = 696;
        for (var index = 0; index < 119; index++) {
          final frame = await codec.getNextFrame();
          try {
            expect((frame.image.width, frame.image.height), (540, 696));
            final data = (await frame.image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final bytes = data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
            first ??= Uint8List.fromList(bytes);
            for (var x = 0; x < 540; x++) {
              expect(bytes[x * 4 + 3], lessThanOrEqualTo(2));
              expect(
                bytes[((696 - 1) * 540 + x) * 4 + 3],
                lessThanOrEqualTo(2),
              );
            }
            for (var y = 0; y < peak; y++) {
              if ([for (var x = 0; x < 540; x++) bytes[(y * 540 + x) * 4 + 3]]
                  .any((a) => a > 2)) {
                peak = y;
                break;
              }
            }
            duration += frame.duration;
          } finally {
            frame.image.dispose();
          }
        }
        expect(peak, inInclusiveRange(1, 8));
        expect(duration.inMilliseconds, 4957);
        // Codec rewind is prefetched offscreen; it must return the actual first
        // frame even though the asset itself is marked for a single playback.
        final rewind = await codec.getNextFrame();
        try {
          final data = (await rewind.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          expect(
            listEquals(
              first,
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            ),
            isTrue,
          );
        } finally {
          rewind.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    },
  );

  test('offline clip has real alpha, infinite loop, safe bounds and matching seam/still', () async {
    final data = await rootBundle.load(AppAssets.homeNovaLoop);
    expect(data.lengthInBytes, lessThan(4500000));
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      expect(codec.frameCount, 119);
      expect(codec.repetitionCount, -1);
      Uint8List? first;
      Uint8List? last;
      var duration = Duration.zero;
      var changed = false;
      var softAlpha = false;
      final timer = Stopwatch()..start();
      for (var i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        try {
          final image = frame.image;
          expect((image.width, image.height), (432, 512));
          expect(image.width * image.height * 4, lessThan(1024 * 1024));
          final rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final bytes = rgba.buffer.asUint8List(
            rgba.offsetInBytes,
            rgba.lengthInBytes,
          );
          first ??= Uint8List.fromList(bytes);
          if (i == 30) changed = !listEquals(first, bytes);
          if (i == codec.frameCount - 1) last = Uint8List.fromList(bytes);
          for (final pixel in [
            0,
            image.width - 1,
            (image.height - 1) * image.width,
            image.width * image.height - 1,
          ]) {
            expect(bytes[pixel * 4 + 3], lessThanOrEqualTo(2));
          }
          if (!softAlpha) {
            for (var at = 3; at < bytes.length; at += 4) {
              if (bytes[at] > 2 && bytes[at] < 250) {
                softAlpha = true;
                break;
              }
            }
          }
          duration += frame.duration;
        } finally {
          frame.image.dispose();
        }
      }
      expect(duration.inMilliseconds, inInclusiveRange(4950, 4965));
      expect(changed, isTrue);
      expect(softAlpha, isTrue);
      expect(listEquals(first, last), isTrue);
      final poster = await rootBundle.load(AppAssets.homeNovaStill);
      final still = await ui.instantiateImageCodec(
        poster.buffer.asUint8List(poster.offsetInBytes, poster.lengthInBytes),
      );
      try {
        expect(still.frameCount, 1);
        final frame = await still.getNextFrame();
        try {
          final rgba = (await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          expect(
            listEquals(
              first,
              rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
            ),
            isTrue,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        still.dispose();
      }
      // ignore: avoid_print
      print(
        'Home WebP: 119 RGBA frames, ${data.lengthInBytes} bytes, ${duration.inMilliseconds} ms loop; decode/alpha checks ${timer.elapsedMilliseconds} ms host wall time',
      );
    } finally {
      codec.dispose();
    }
  });

  testWidgets(
    'real image frames animate, reduced motion freezes and lifecycle pauses',
    (tester) async {
      final controller = NovaCharacterController();
      addTearDown(controller.dispose);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      var reduced = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return _host(controller, reduced: reduced);
          },
        ),
      );
      await _warm(tester);
      final first = await _pixels(tester);
      await _advanceFrames(tester);
      expect(listEquals(first, await _pixels(tester)), isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(TickerMode.valuesOf(tester.element(_loop())).enabled, isFalse);
      final paused = await _pixels(tester);
      await _advanceFrames(tester);
      expect(listEquals(paused, await _pixels(tester)), isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(TickerMode.valuesOf(tester.element(_loop())).enabled, isTrue);
      rebuild(() => reduced = true);
      await tester.pump();
      await _warm(tester);
      expect(_loop(), findsNothing);
      final still = await _pixels(tester);
      await _advanceFrames(tester);
      expect(listEquals(still, await _pixels(tester)), isTrue);
      await _dispose(tester, controller);
    },
  );

  testWidgets(
    'queues one jump at idle boundary, plays every frame once and restarts idle',
    (tester) async {
      final controller = NovaCharacterController();
      addTearDown(controller.dispose);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final busy = <bool>[];
      await tester.pumpWidget(_host(controller, onBusy: busy.add));
      await _warm(tester);
      await _oneFrame(tester, milliseconds: 37);
      expect(_index(tester), 1); // 41-42 ms source hold at 1.15x.
      for (var i = 0; i < 3; i++) {
        await _oneFrame(tester);
      }
      final initial = _index(tester);
      final originalRect = tester.getRect(_loop());
      expect(initial, greaterThan(0));
      controller.play(NovaExpression.tapReaction, then: NovaExpression.idle);
      for (var tap = 0; tap < 30; tap++) {
        controller.play(NovaExpression.tapReaction);
      }
      await tester.pump();
      expect(_index(tester), initial);
      expect(busy, [true]);
      expect(_jump(), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      expect(_index(tester), initial);
      expect(busy, [true]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      final idleFrames = <int>[];
      final rushStarted = tester.binding.clock.now();
      for (var step = 0; step < 450 && _jump().evaluate().isEmpty; step++) {
        final index = _index(tester);
        if (idleFrames.isEmpty || idleFrames.last != index) {
          idleFrames.add(index);
        }
        await _oneFrame(tester, milliseconds: 1);
      }
      expect(
        tester.binding.clock.now().difference(rushStarted).inMilliseconds,
        inInclusiveRange(200, 400),
      );
      expect(idleFrames, [for (var i = initial; i < 119; i++) i]);
      expect(_jump(), findsOneWidget);
      expect(_index(tester), 0);
      final jumpRect = tester.getRect(_jump());
      final sourceScale = originalRect.height / 1108;
      expect(jumpRect.left, closeTo(originalRect.left - 8 * sourceScale, .001));
      expect(jumpRect.top, closeTo(originalRect.top - 282 * sourceScale, .001));
      expect(jumpRect.height, closeTo(1392 * sourceScale, .001));
      // The outgoing idle isn't retained or crossfaded: exactly one image plays.
      expect(_raw(), findsOneWidget);
      final jumpFrames = <int>[0];
      await _oneFrame(tester);
      await _oneFrame(tester);
      expect(_index(tester), 1); // Jump advances within 40 ms at 1.20x.
      var pausedJump = false;
      for (var step = 0; step < 300 && _jump().evaluate().isNotEmpty; step++) {
        final index = _index(tester);
        if (jumpFrames.isEmpty || jumpFrames.last != index) {
          jumpFrames.add(index);
        }
        controller.play(NovaExpression.tapReaction);
        if (index == 38) await _capture(tester, 'jump-peak');
        if (index == 36 && !pausedJump) {
          pausedJump = true;
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 10));
          expect(_index(tester), 36);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
        }
        await _oneFrame(tester);
      }
      expect(jumpFrames, [for (var i = 0; i < 119; i++) i]);
      expect(busy, [true, false]);
      expect(_loop(), findsOneWidget);
      expect(_index(tester), 0);
      expect(tester.getRect(_loop()), originalRect);
      await _capture(tester, 'idle-restarted');
      await _oneFrame(tester, milliseconds: 37);
      expect(_index(tester), 1); // Returning idle retains 1.15x playback.
      expect(find.byType(NovaCharacter), findsNothing);
      expect(
        tester.getSize(find.byType(HomeNovaCharacter)),
        const Size(240, 240),
      );
      await _dispose(tester, controller);
    },
  );

  testWidgets(
    'controller replacement and disposal during image loading detach listeners',
    (tester) async {
      final first = NovaCharacterController();
      final second = NovaCharacterController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(_host(first));
      await tester.pumpWidget(_host(second));
      first.play(NovaExpression.tapReaction);
      await tester.pump();
      expect(find.byType(NovaCharacter), findsNothing);
      second.play(NovaExpression.tapReaction);
      await tester.pump();
      expect(find.byType(NovaCharacter), findsNothing);
      expect(_jump(), findsNothing);
      await _dispose(tester, second);
    },
  );

  testWidgets(
    'reduced motion cancels pending/playing jumps and preserves static happy taps',
    (tester) async {
      final controller = NovaCharacterController();
      addTearDown(controller.dispose);
      var reduced = false;
      late StateSetter rebuild;
      final busy = <bool>[];
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return _host(controller, reduced: reduced, onBusy: busy.add);
          },
        ),
      );
      await _warm(tester);
      controller.play(NovaExpression.tapReaction);
      expect(busy, [true]);
      rebuild(() => reduced = true);
      await tester.pump();
      expect(busy, [true, false]);
      controller.play(NovaExpression.happy);
      await tester.pump();
      await _warm(tester);
      expect(find.byType(NovaCharacter), findsOneWidget);
      expect(
        tester.widget<NovaCharacter>(find.byType(NovaCharacter)).expression,
        NovaExpression.happy,
      );
      rebuild(() => reduced = false);
      await tester.pump();
      controller.play(NovaExpression.tapReaction);
      for (var step = 0; step < 300 && _jump().evaluate().isEmpty; step++) {
        await _oneFrame(tester);
      }
      expect(_jump(), findsOneWidget);
      for (var step = 0; step < 20; step++) {
        await _oneFrame(tester);
      }
      expect(_index(tester), greaterThan(0));
      rebuild(() => reduced = true);
      await tester.pump();
      expect(busy.last, isFalse);
      expect(_jump(), findsNothing);
      rebuild(() => reduced = false);
      await tester.pump();
      controller.play(NovaExpression.tapReaction);
      for (var step = 0; step < 300 && _jump().evaluate().isEmpty; step++) {
        await _oneFrame(tester);
      }
      expect(_jump(), findsOneWidget);
      expect(_index(tester), 0);
      await _dispose(tester, controller);
    },
  );
}

Finder _raw() => find.byWidgetPredicate(
  (widget) =>
      widget is RawImage &&
      widget.debugImageLabel?.startsWith('Home Nova ') == true,
);
Finder _loop() => find.byKey(const ValueKey('Home Nova idle'));
Finder _jump() => find.byKey(const ValueKey('Home Nova jump'));
int _index(WidgetTester tester) => int.parse(
  RegExp(r'frame (\d+)/')
      .firstMatch(tester.widget<RawImage>(_raw()).debugImageLabel!)!
      .group(1)!,
);

Widget _host(
  NovaCharacterController controller, {
  bool reduced = false,
  ValueChanged<bool>? onBusy,
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        key: _stage,
        child: SizedBox.square(
          dimension: 360,
          child: Center(
            child: HomeNovaCharacter(
              controller: controller,
              size: 240,
              onBusyChanged: onBusy,
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _warm(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(HomeNovaCharacter));
    await precacheImage(const AssetImage(AppAssets.homeNovaStill), context);
    await NovaAssets.preload(
      context,
      expressions: const [NovaExpression.happy],
    );
  });
  final reduced = MediaQuery.disableAnimationsOf(
    tester.element(find.byType(HomeNovaCharacter)),
  );
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
    if (_raw().evaluate().isNotEmpty || (reduced && attempt >= 6)) return;
  }
  fail('Home clips did not preload.');
}

Future<void> _oneFrame(WidgetTester tester, {int milliseconds = 20}) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 3)),
  );
  await tester.pump(Duration(milliseconds: milliseconds));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 3)),
  );
  await tester.pump();
}

Future<void> _advanceFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await _oneFrame(tester);
  }
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      return Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('HOME_JUMP_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final folder = Directory('build/home_jump_review')
        ..createSync(recursive: true);
      await File('${folder.path}/$name.png').writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

Future<void> _dispose(
  WidgetTester tester,
  NovaCharacterController controller,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump(const Duration(seconds: 1));
  // A leaked subscription would call setState on a disposed Home widget.
  controller.play(NovaExpression.tapReaction);
  await tester.pump();
  expect(tester.binding.transientCallbackCount, 0);
  expect(tester.takeException(), isNull);
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
}
