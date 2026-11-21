import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/core/typography/app_type.dart';
import 'package:novadoku/shared/layouts/nova_background.dart';
import 'package:novadoku/shared/widgets/nova_arrival.dart';
import 'package:novadoku/shared/widgets/nova_buttons.dart';
import 'package:novadoku/shared/widgets/nova_pressable.dart';

void main() {
  test('typography uses explicit heading and supporting weights with offline fallbacks', () {
    expect(AppType.screenTitle.fontFamily, 'DynaPuff');
    expect(AppType.screenTitle.fontWeight, FontWeight.w600);
    expect(AppType.display.fontWeight, FontWeight.w700);
    expect(AppType.tutorialTitle.fontWeight, FontWeight.w700);
    expect(AppType.primaryButton.fontFamily, 'Nunito Sans');
    expect(AppType.primaryButton.fontWeight, FontWeight.w700);
    expect(AppType.description.fontWeight, FontWeight.w600);
    expect(
      AppType.display.fontFamilyFallback,
      containsAll(['Noto Sans', 'Noto Sans Devanagari', 'Noto Sans JP']),
    );
  });

  testWidgets(
    'bundled font cmaps cover every catalog character in all seven languages',
    (tester) async {
      final covered = <int>{};
      for (final file in [
        'DynaPuff',
        'NunitoSans',
        'NotoSans',
        'NotoSansDevanagari',
        'NotoSansJP',
      ]) {
        covered.addAll(
          _characters(await rootBundle.load('assets/fonts/$file.ttf')),
        );
      }
      for (final locale in ['en', 'hi', 'ja', 'fr', 'de', 'ru', 'pt']) {
        // Source catalogs are test inputs, not newly bundled runtime assets.
        final catalog = jsonDecode(
          (await tester.runAsync(
            () => File('lib/l10n/app_$locale.arb').readAsString(),
          ))!,
        ) as Map<String, dynamic>;
        final missing = <int>{};
        for (final entry in catalog.entries) {
          if (entry.key.startsWith('@') || entry.value is! String) continue;
          for (final code in (entry.value as String).runes) {
            if (code > 32 && !covered.contains(code)) missing.add(code);
          }
        }
        expect(
          missing.map((c) => 'U+${c.toRadixString(16)}'),
          isEmpty,
          reason: locale,
        );
      }
    },
  );

  testWidgets(
    'branding arrival stays interactive, does not replay and respects live reduced motion',
    (tester) async {
      var reduced = false;
      var label = 'Play';
      var taps = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: Center(
                  child: NovaArrival(
                    child: SizedBox(
                      width: 200,
                      child: NovaPrimaryButton(
                        label: label,
                        feedback: null,
                        onPressed: () => taps++,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      double opacity() => tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(NovaArrival),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(), 0);
      await tester.tap(find.byType(NovaPrimaryButton));
      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 80));
      expect(opacity(), inExclusiveRange(0, 1));
      rebuild(() => reduced = true);
      await tester.pumpAndSettle();
      expect(opacity(), 1);
      rebuild(() {
        reduced = false;
        label = 'Jouer';
      });
      await tester.pump();
      expect(opacity(), 1);
      await tester.tap(find.text('Jouer'));
      expect(taps, 2);
      await _dispose(tester);
    },
  );

  testWidgets(
    'CTA, icon and compact presses differ without extra actions or reduced-motion movement',
    (tester) async {
      var reduced = false;
      var taps = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: Column(
                  children: [
                    NovaPrimaryButton(
                      label: 'Play',
                      feedback: null,
                      onPressed: () => taps++,
                    ),
                    NovaIconButton(
                      icon: Icons.close,
                      label: 'Close',
                      onPressed: () => taps++,
                    ),
                    NovaPressable(
                      label: 'Compact',
                      radius: BorderRadius.zero,
                      onPressed: () {},
                      child: const SizedBox.square(dimension: 48),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      final cta = find.byType(NovaPrimaryButton);
      final down = await tester.startGesture(tester.getCenter(cta));
      await tester.pump(const Duration(milliseconds: 130));
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(of: cta, matching: find.byType(AnimatedScale)),
            )
            .scale,
        .985,
      );
      expect(
        tester
            .widget<AnimatedSlide>(
              find.descendant(of: cta, matching: find.byType(AnimatedSlide)),
            )
            .offset
            .dy,
        .025,
      );
      expect(taps, 0);
      rebuild(() => reduced = true);
      await tester.pump();
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(of: cta, matching: find.byType(AnimatedScale)),
            )
            .scale,
        1,
      );
      expect(
        tester
            .widget<AnimatedSlide>(
              find.descendant(of: cta, matching: find.byType(AnimatedSlide)),
            )
            .offset,
        Offset.zero,
      );
      await down.up();
      expect(taps, 1);
      rebuild(() => reduced = false);
      await tester.pumpAndSettle();
      final icon = find.byType(NovaIconButton);
      final press = await tester.startGesture(tester.getCenter(icon));
      await tester.pump(const Duration(milliseconds: 130));
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(of: icon, matching: find.byType(AnimatedScale)),
            )
            .scale,
        .94,
      );
      expect(
        find.descendant(of: icon, matching: find.byType(AnimatedSlide)),
        findsNothing,
      );
      await press.cancel();
      await tester.pumpAndSettle();
      expect(taps, 1);
      await _dispose(tester);
    },
  );

  testWidgets(
    'background accents settle without perpetual ticks or replay on rebuild',
    (tester) async {
      late StateSetter rebuild;
      var reduced = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: const NovaBackground(
                  style: NovaBackgroundStyle.hero,
                  child: SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      rebuild(() => reduced = true);
      await tester.pumpAndSettle();
      rebuild(() => reduced = false);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await _dispose(tester);
    },
  );
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  expect(tester.binding.transientCallbackCount, 0);
  expect(tester.takeException(), isNull);
}

/// Read real Unicode cmap mappings rather than treating tofu glyphs as success.
Set<int> _characters(ByteData font) {
  var cmap = 0;
  for (var i = 0; i < font.getUint16(4); i++) {
    final table = 12 + i * 16;
    if (font.getUint32(table) == 0x636d6170) cmap = font.getUint32(table + 8);
  }
  final result = <int>{};
  for (var i = 0; i < font.getUint16(cmap + 2); i++) {
    final record = cmap + 4 + i * 8;
    final platform = font.getUint16(record);
    final encoding = font.getUint16(record + 2);
    if (platform != 0 &&
        !(platform == 3 && (encoding == 1 || encoding == 10))) {
      continue;
    }
    final sub = cmap + font.getUint32(record + 4);
    final format = font.getUint16(sub);
    if (format == 12) {
      for (var group = 0; group < font.getUint32(sub + 12); group++) {
        final at = sub + 16 + group * 12;
        final start = font.getUint32(at);
        final end = font.getUint32(at + 4);
        final glyph = font.getUint32(at + 8);
        for (var code = start; code <= end; code++) {
          if (glyph + code - start != 0) result.add(code);
        }
      }
    } else if (format == 4) {
      final count = font.getUint16(sub + 6) ~/ 2;
      final ends = sub + 14;
      final starts = ends + count * 2 + 2;
      final deltas = starts + count * 2;
      final ranges = deltas + count * 2;
      for (var segment = 0; segment < count; segment++) {
        final start = font.getUint16(starts + segment * 2);
        final end = font.getUint16(ends + segment * 2);
        final delta = font.getInt16(deltas + segment * 2);
        final range = font.getUint16(ranges + segment * 2);
        for (var code = start; code <= end && code < 0xffff; code++) {
          var glyph = range == 0
              ? code
              : font.getUint16(
                  ranges + segment * 2 + range + (code - start) * 2,
                );
          if (range == 0 || glyph != 0) glyph = (glyph + delta) & 0xffff;
          if (glyph != 0) result.add(code);
        }
      }
    }
  }
  return result;
}
