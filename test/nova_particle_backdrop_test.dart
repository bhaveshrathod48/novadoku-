import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/shared/widgets/nova_particle_backdrop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final mood in NovaParticleMood.values) {
    testWidgets(
      '$mood keeps child geometry/state, paints only behind and pauses safely',
      (tester) async {
        var reduced = false;
        var ticks = true;
        var builds = 0;
        var taps = 0;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reduced),
                  child: TickerMode(
                    enabled: ticks,
                    child: Center(
                      child: NovaParticleBackdrop(
                        mood: mood,
                        child: Builder(
                          builder: (context) {
                            builds++;
                            return SizedBox.square(
                              dimension: 216,
                              child: TextButton(
                                key: const ValueKey('hero'),
                                onPressed: () => taps++,
                                child: const Text('Nova'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        final original = tester.getRect(find.byKey(const ValueKey('hero')));
        final before = builds;
        final clock = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<NovaAmbientPainter>()
            .single
            .clock;
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(clock.value, greaterThan(0));
        expect(builds, before);
        await tester.tap(find.byKey(const ValueKey('hero')));
        expect(taps, 1);
        update(() => ticks = false);
        await tester.pump();
        final held = clock.value;
        await tester.pump(const Duration(seconds: 1));
        expect(clock.value, held);
        update(() {
          ticks = true;
          reduced = true;
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(clock.value, held);
        update(() => reduced = false);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        final paused = clock.value;
        await tester.pump(const Duration(seconds: 1));
        expect(clock.value, paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.getRect(find.byKey(const ValueKey('hero'))), original);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'themes have distinct bounded paint and a protected portrait center',
    () async {
      final frames = <String>{};
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final mood in NovaParticleMood.values) {
        final local = ui.PictureRecorder();
        NovaAmbientPainter(
          const AlwaysStoppedAnimation(.35),
          mood,
        ).paint(Canvas(local), const Size.square(200));
        final pic = local.endRecording();
        final image = await pic.toImage(200, 200);
        final pixels = (await image.toByteData())!;
        frames.add(pixels.buffer.asUint8List().join(','));
        if (mood != NovaParticleMood.victory && mood != NovaParticleMood.home) {
          expect(pixels.getUint8((100 * 200 + 100) * 4 + 3), 0);
        }
        canvas.drawImage(image, Offset(mood.index * 200.0, 0), Paint());
        image.dispose();
        pic.dispose();
      }
      expect(frames, hasLength(NovaParticleMood.values.length));
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        200 * NovaParticleMood.values.length,
        200,
      );
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final dir = Directory('build/nova_particles')
        ..createSync(recursive: true);
      File('${dir.path}/themes.png').writeAsBytesSync(png.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    },
  );

  testWidgets('Home energy rises during the reaction and returns to ambient', (
    tester,
  ) async {
    var busy = false;
    var reduced = false;
    late StateSetter update;
    const child = SizedBox.square(dimension: 240);
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: Center(
                child: NovaParticleBackdrop(
                  mood: NovaParticleMood.home,
                  intensified: busy,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
    NovaAmbientPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<NovaAmbientPainter>()
        .single;
    expect(painter().energy.value, 0);
    update(() => busy = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(painter().energy.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(painter().energy.value, 1);
    update(() => busy = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 510));
    expect(painter().energy.value, 0);
    update(() {
      busy = true;
      reduced = true;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(painter().energy.value, 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
