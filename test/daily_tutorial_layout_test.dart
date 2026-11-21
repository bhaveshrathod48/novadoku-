import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/router/app_router.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/validator/puzzle_validator.dart';
import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/widgets/nova_glyph.dart';
import 'package:novadoku/features/tutorial/tutorial_nova.dart';

import 'support/feedback_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  for (final size in [
    const Size(360, 640),
    const Size(360, 740),
    const Size(390, 844),
    const Size(800, 1280),
  ]) {
    for (final (route, scrollKey, bottomText) in [
      (
        AppRoute.dailyChallenge,
        'daily vertical layout',
        'One Nova per row, column and region.\nNo touching, even diagonally.',
      ),
      (AppRoute.howToPlay, 'tutorial vertical layout', 'Let’s play'),
    ]) {
      testWidgets('${route.name} fills safe height on $size', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
        addTearDown(tester.view.reset);
        await tester.runAsync(() async {
          for (final family in ['Nunito Sans', 'DynaPuff']) {
            await (FontLoader(family)..addFont(
                  rootBundle.load(
                    'assets/fonts/${family.replaceAll(' ', '')}.ttf',
                  ),
                ))
                .load();
          }
        });
        final container = ProviderContainer(
          overrides: [
            settingsStoreProvider.overrideWithValue(const _Settings()),
            audioServiceProvider.overrideWithValue(RecordingAudio()),
            hapticServiceProvider.overrideWithValue(RecordingHaptics()),
          ],
        );
        addTearDown(container.dispose);
        container.read(appRouterProvider).goNamed(route.name);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const NovaApp(),
          ),
        );
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(ValueKey(scrollKey)),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.maxScrollExtent, closeTo(0, .1));
        if (route == AppRoute.howToPlay) {
          final mascot = tester.getRect(find.byType(TutorialNova));
          final heading = tester.getRect(
            find.text('Small rules.\nBright possibilities.'),
          );
          expect(mascot.width, inInclusiveRange(64, 176));
          expect(mascot.height, closeTo(mascot.width, .1));
          expect(mascot.center.dx, closeTo(size.width / 2, .1));
          expect(mascot.bottom, lessThan(heading.top));
          if (size == const Size(390, 844)) {
            expect(mascot.width, 176); // Previously an 88 dp square.
          }
        }
        final bottom = find.text(bottomText);
        expect(bottom.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(bottom).dy, greaterThan(size.height - 80));
        expect(
          tester.getTopLeft(find.bySemanticsLabel('Back')).dy,
          inInclusiveRange(36, 40),
        );
        expect(container.read(puzzleSessionProvider), isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'tutorial partial diagrams show a single Nova and exclude a diagonal neighbor',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(const _Settings()),
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          hapticServiceProvider.overrideWithValue(RecordingHaptics()),
        ],
      );
      addTearDown(container.dispose);
      container.read(appRouterProvider).goNamed(AppRoute.howToPlay.name);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('One Nova in every\nrow and column.'), findsOneWidget);
      expect(find.text('One Nova in each\ncoloured region.'), findsOneWidget);
      expect(find.text('Keep Novas apart,\neven diagonally.'), findsOneWidget);
      final portraits = find.byWidgetPredicate(
        (widget) =>
            widget is NovaArtworkImage && widget.artwork == NovaArtwork.grid,
      );
      expect(portraits, findsNWidgets(3));
      final exclusion = find.byWidgetPredicate(
        (widget) => widget is NovaGlyph && widget.kind == NovaGlyphKind.cross,
      );
      expect(exclusion, findsOneWidget);
      final diagonal =
          tester.getCenter(exclusion) - tester.getCenter(portraits.last);
      expect(diagonal.dx, greaterThan(0));
      expect(diagonal.dy, closeTo(diagonal.dx, .1));
      final board = PuzzleDefinition(
        id: 'rule-example',
        size: 4,
        regionIds: List.generate(16, (index) => index % 4),
      );
      expect(
        PuzzleValidator.conflict(
          board,
          (row: 2, column: 2),
          [(row: 1, column: 1)],
        ),
        PlacementConflict.touching,
      );
      final strings = lookupAppLocalizations(const Locale('en'));
      expect(strings.ruleRows, 'One Nova in every\nrow and column.');
      expect(tester.takeException(), isNull);
    },
  );
}

class _Settings implements SettingsStore {
  const _Settings();
  @override
  Future<AppSettings> read() async => const AppSettings();
  @override
  Future<void> write(AppSettings settings) async {}
}
