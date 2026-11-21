import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/characters/nova_character.dart';

const _stage = Key('character stage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final expression in NovaExpression.values) {
    testWidgets('${expression.name} animates and releases its ticker', (
      tester,
    ) async {
      final completed = <NovaExpression>[];
      await tester.pumpWidget(
        _host(
          NovaCharacter(
            expression: expression,
            size: 96,
            onCompleted: completed.add,
          ),
        ),
      );
      await _warm(tester, [expression]);
      final first = await _pixels(tester);
      await tester.pump(expression.duration ~/ 2);
      expect(listEquals(first, await _pixels(tester)), isFalse);
      await tester.pump(expression.duration);
      expect(completed, expression.loop ? isEmpty : [expression]);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'all seventeen textures decode offline with alpha and bounded sizes',
    () async {
      var compressedBytes = 0;
      var totalDecode = 0;
      var maxDecode = 0;
      final paths = [
        for (final art in NovaArtwork.values) (path: art.asset, atlas: false),
        for (final clip in NovaExpression.values)
          (path: clip.asset, atlas: true),
      ];
      expect(paths.length, 17);

      for (final entry in paths) {
        final bytes = await rootBundle.load(entry.path);
        compressedBytes += bytes.lengthInBytes;
        final timer = Stopwatch()..start();
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        try {
          expect(codec.frameCount, 1, reason: entry.path);
          final frame = await codec.getNextFrame();
          timer.stop();
          totalDecode += timer.elapsedMicroseconds;
          if (timer.elapsedMicroseconds > maxDecode) {
            maxDecode = timer.elapsedMicroseconds;
          }
          try {
            final image = frame.image;
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            int alpha(int x, int y) =>
                data.getUint8((y * image.width + x) * 4 + 3);
            expect(alpha(0, 0), 0, reason: entry.path);
            expect(
              alpha(image.width - 1, image.height - 1),
              0,
              reason: entry.path,
            );
            if (entry.atlas) {
              expect(image.width, image.height);
              expect(image.width, anyOf(512, 768));
              final side = image.width ~/ 2;
              final fingerprints = <int>{};
              for (var pose = 0; pose < 4; pose++) {
                final x = (pose % 2) * side;
                final y = (pose ~/ 2) * side;
                expect(alpha(x, y), 0, reason: entry.path);
                var opaque = 0;
                var fingerprint = 0;
                for (var row = y; row < y + side; row += 5) {
                  for (var col = x; col < x + side; col += 5) {
                    if (alpha(col, row) > 200) opaque++;
                    fingerprint =
                        (fingerprint * 31 +
                            data.getUint32((row * image.width + col) * 4)) &
                        0x7fffffff;
                  }
                }
                expect(opaque, greaterThan(500), reason: entry.path);
                expect(
                  fingerprints.add(fingerprint),
                  isTrue,
                  reason: entry.path,
                );
              }
            } else {
              expect(image.width, lessThanOrEqualTo(1024));
              expect(image.height, lessThanOrEqualTo(1024));
              expect(
                alpha(image.width ~/ 2, image.height ~/ 2),
                greaterThan(200),
              );
            }
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }

      expect(compressedBytes, lessThan(3 * 1024 * 1024));
      // ignore: avoid_print
      print(
        'Nova textures: $compressedBytes compressed bytes; '
        '${(totalDecode / 1000).toStringAsFixed(1)} ms serial decode, '
        '${(maxDecode / 1000).toStringAsFixed(1)} ms slowest texture.',
      );
    },
  );

  testWidgets(
    'idle plays pose frames and loops; tap completes and returns to idle',
    (tester) async {
      final controller = NovaCharacterController();
      addTearDown(controller.dispose);
      final completed = <NovaExpression>[];
      await tester.pumpWidget(
        _host(
          NovaCharacter(
            size: 96,
            controller: controller,
            onCompleted: completed.add,
            semanticLabel: 'Nova',
          ),
        ),
      );
      await _warm(tester, [NovaExpression.idle, NovaExpression.tapReaction]);
      final resting = await _pixels(tester);
      await tester.pump(const Duration(milliseconds: 970));
      expect(listEquals(resting, await _pixels(tester)), isFalse);
      await tester.pump(
        NovaExpression.idle.duration - const Duration(milliseconds: 970),
      );
      expect(listEquals(resting, await _pixels(tester)), isTrue);
      expect(completed, isEmpty);

      controller.play(NovaExpression.tapReaction, then: NovaExpression.idle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 230));
      expect(listEquals(resting, await _pixels(tester)), isFalse);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(completed, [NovaExpression.tapReaction]);
      expect(listEquals(resting, await _pixels(tester)), isTrue);
      expect(find.bySemanticsLabel('Nova'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      controller.play(NovaExpression.wrong);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion requests a representative still and skips completion',
    (tester) async {
      final controller = NovaCharacterController(NovaExpression.celebration);
      addTearDown(controller.dispose);
      final finished = <NovaExpression>[];
      Widget character() => NovaCharacter(
        size: 96,
        controller: controller,
        onCompleted: finished.add,
      );
      await tester.pumpWidget(_host(character(), reduced: true));
      await _warm(tester, [NovaExpression.celebration, NovaExpression.wrong]);
      final victory = await _pixels(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(listEquals(victory, await _pixels(tester)), isTrue);
      expect(tester.binding.transientCallbackCount, 0);

      controller.play(NovaExpression.wrong, then: NovaExpression.idle);
      await tester.pump();
      final wrong = await _pixels(tester);
      expect(listEquals(victory, wrong), isFalse);
      await tester.pump(const Duration(seconds: 3));
      expect(listEquals(wrong, await _pixels(tester)), isTrue);
      expect(finished, isEmpty);

      await tester.pumpWidget(_host(character()));
      await tester.pump();
      expect(listEquals(wrong, await _pixels(tester)), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'a missing atlas surfaces an error and a valid expression recovers',
    (tester) async {
      final controller = NovaCharacterController(NovaExpression.wrong);
      addTearDown(controller.dispose);
      final errors = <Object>[];
      final assetBundle = _MissingAtlasBundle(NovaExpression.wrong.asset);
      await tester.pumpWidget(
        _host(
          NovaCharacter(
            size: 96,
            controller: controller,
            animate: false,
            onAssetError: (error, _) => errors.add(error),
          ),
          bundle: assetBundle,
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byKey(_stage));
        await expectLater(
          NovaAssets.preload(context, expressions: [NovaExpression.wrong]),
          throwsA(isA<StateError>()),
        );
      });
      await tester.pump();
      expect(errors, hasLength(1));
      final blank = await _pixels(tester);
      expect(blank.every((byte) => byte == 0), isTrue);

      controller.play(NovaExpression.correct);
      await _warm(tester, [NovaExpression.correct]);
      expect((await _pixels(tester)).any((byte) => byte != 0), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid commands and removal during an asset read release listeners',
    (tester) async {
      final controller = NovaCharacterController();
      addTearDown(controller.dispose);
      final completed = <NovaExpression>[];
      Widget character() => NovaCharacter(
        size: 96,
        controller: controller,
        onCompleted: completed.add,
      );
      await tester.pumpWidget(_host(character()));
      await _warm(tester, [
        NovaExpression.idle,
        NovaExpression.tapReaction,
        NovaExpression.correct,
      ]);
      controller.play(NovaExpression.tapReaction);
      controller.play(NovaExpression.correct);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(completed, [NovaExpression.correct]);
      await tester.pumpWidget(_host(character(), reduced: true));
      await tester.pumpWidget(_host(character()));
      await tester.pump(const Duration(seconds: 1));
      expect(completed, [NovaExpression.correct]);
      controller.play(NovaExpression.sleeping);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(Widget character, {bool reduced = false, AssetBundle? bundle}) =>
    DefaultAssetBundle(
      bundle: bundle ?? rootBundle,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(key: _stage, child: character),
          ),
        ),
      ),
    );

Future<void> _warm(
  WidgetTester tester,
  List<NovaExpression> expressions,
) async {
  await tester.runAsync(
    () => NovaAssets.preload(
      tester.element(find.byKey(_stage)),
      expressions: expressions,
    ),
  );
  await tester.pump();
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
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }))!;
}

final class _MissingAtlasBundle extends CachingAssetBundle {
  _MissingAtlasBundle(this.missing);

  final String missing;

  @override
  Future<ByteData> load(String key) async {
    if (key == missing) throw StateError('Missing Nova atlas.');
    return rootBundle.load(key);
  }
}
