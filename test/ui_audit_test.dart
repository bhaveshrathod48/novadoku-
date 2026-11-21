import 'package:novadoku/features/gameplay/hint_nova.dart';
import 'package:novadoku/features/tutorial/tutorial_nova.dart';
import 'package:novadoku/features/daily_challenge/daily_nova.dart';
import 'package:novadoku/features/gameplay/level_complete_nova.dart';
import 'package:novadoku/features/gameplay/try_again_nova.dart';
import 'package:novadoku/core/constants/app_assets.dart';
import 'package:novadoku/features/gameplay/gameplay_nova.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';

import 'support/feedback_fakes.dart';
import 'support/gameplay_gestures.dart';

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

  for (final viewport in [
    (name: 'phone', size: const Size(390, 844), scale: 1.0),
    (name: 'compact', size: const Size(320, 568), scale: 2.0),
    (name: 'tablet', size: const Size(800, 1280), scale: 1.0),
  ]) {
    testWidgets('all ten reference surfaces on ${viewport.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport.size;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = viewport.scale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(const _Settings()),
          puzzleWorkProvider.overrideWithValue(const _Work(6)),
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          hapticServiceProvider.overrideWithValue(RecordingHaptics()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(puzzleGameProvider.notifier);
      await controller.startLevel(3);
      final stage = GlobalKey();
      await tester.runAsync(() async {
        for (final family in ['Nunito Sans', 'DynaPuff']) {
          await (FontLoader(family)..addFont(
                rootBundle.load(
                  'assets/fonts/${family.replaceAll(' ', '')}.ttf',
                ),
              ))
              .load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: stage,
          child: UncontrolledProviderScope(
            container: container,
            child: const NovaApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => NovaAssets.preload(
          tester.element(find.byType(Scaffold)),
          artwork: NovaArtwork.values,
          expressions: NovaExpression.values,
        ),
      );
      final router = container.read(appRouterProvider);
      Future<void> capture(String surface) async {
        await tester.pumpAndSettle();
        if (viewport.name == 'phone' &&
            (surface == 'gameplay' || surface == 'mistake')) {
          expect(
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .maxScrollExtent,
            0,
            reason: '$surface fits with the real fonts',
          );
          expect(find.text('Reset').hitTestable(), findsOneWidget);
          expect(find.bySemanticsLabel('Back').hitTestable(), findsOneWidget);
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '${viewport.name} $surface',
        );
        if (!const bool.fromEnvironment('QA_CAPTURE')) return;
        final hint = find.byType(HintNova);
        if (hint.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppAssets.hintNovaStill),
              tester.element(hint.first),
            ),
          );
          await tester.pump();
        }
        final tutorial = find.byType(TutorialNova);
        if (tutorial.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppAssets.tutorialNovaStill),
              tester.element(tutorial.first),
            ),
          );
          await tester.pump();
        }
        final daily = find.byType(DailyNova);
        if (daily.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppAssets.dailyNovaStill),
              tester.element(daily.first),
            ),
          );
          await tester.pump();
        }
        final complete = find.byType(LevelCompleteNova);
        if (complete.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppAssets.levelCompleteNovaStill),
              tester.element(complete.first),
            ),
          );
          await tester.pump();
        }
        final retry = find.byType(TryAgainNova);
        if (retry.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppAssets.tryAgainNovaStill),
              tester.element(retry.first),
            ),
          );
          await tester.pump();
        }
        final playback = find.byType(GameplayNovaPlayback);
        if (playback.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppAssets.gameplayNovaStill),
              tester.element(playback.first),
            ),
          );
          await tester.pump();
        }
        final boundary =
            stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            final file = File('build/qa09/${viewport.name}-$surface.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
        if (tester.widget(finder) is NovaGridCell) {
          await placeNova(tester, finder);
        } else {
          await tester.tap(finder);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Finder cell(int row, int column) =>
          find.byKey(ValueKey((row: row, column: column)));
      await capture('home');
      router.goNamed(AppRoute.settings.name);
      await capture('settings');
      await tap(find.bySemanticsLabel('Close'));
      router.goNamed(AppRoute.dailyChallenge.name);
      await capture('daily');
      await tap(find.bySemanticsLabel('Settings'));
      await tap(find.bySemanticsLabel('Close'));
      router.goNamed(AppRoute.howToPlay.name);
      await capture('tutorial');
      await tap(find.text('Let’s play'));
      await capture('gameplay');
      await tap(find.text('Reset'));
      await capture('reset');
      await tap(find.text('Cancel'));
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final correct = puzzle.columnsByRow.first;
      final note = cell(0, (correct + 1) % puzzle.definition.size);
      await markCell(tester, note);
      await capture('white-marks');
      await markCell(tester, note);
      await tap(cell(0, correct));
      await tap(find.text('Hint'));
      await capture('hint');
      await tap(find.text('Cancel'));
      await tap(cell(1, correct));
      await capture('mistake');
      await tap(cell(2, correct));
      await tap(cell(3, correct));
      await capture('retry');
      await tap(find.text('Try again'));
      await tap(find.bySemanticsLabel('Back'));
      await capture('leave');
      await tap(find.text('Keep playing'));
      for (final (row, column) in puzzle.columnsByRow.indexed) {
        if ((row: row, column: column) ==
            container.read(puzzleSessionProvider)!.startingNova) {
          continue;
        }
        await tap(cell(row, column));
      }
      await capture('complete');
      await tap(find.text('Back home'));
    });
  }
  for (var size = 4; size <= 10; size++) {
    testWidgets('play complete puzzle of size $size on compact screen', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(
            const _Settings(reduced: true),
          ),
          puzzleWorkProvider.overrideWithValue(_Work(size)),
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          hapticServiceProvider.overrideWithValue(RecordingHaptics()),
        ],
      );
      addTearDown(container.dispose);
      container.read(appRouterProvider).goNamed(AppRoute.gameplay.name);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NovaGridCell), findsNWidgets(size * size));
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      for (final (row, column) in puzzle.columnsByRow.indexed) {
        if ((row: row, column: column) ==
            container.read(puzzleSessionProvider)!.startingNova) {
          continue;
        }
        final target = find.byKey(ValueKey((row: row, column: column)));
        await tester.ensureVisible(target);
        await placeNova(tester, target);
        await tester.pumpAndSettle();
      }
      expect(
        container.read(puzzleSessionProvider)!.status,
        PuzzleStatus.completed,
      );
      expect(find.text('Beautifully done.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  }
}

class _Settings implements SettingsStore {
  const _Settings({this.reduced = false});
  final bool reduced;
  @override
  Future<AppSettings> read() async => AppSettings();
  @override
  Future<void> write(AppSettings settings) async {}
}

class _Work implements PuzzleWork {
  const _Work(this.size);
  final int size;
  @override
  Future<GeneratedPuzzle> level(int number) async =>
      PuzzleGenerator.generate(size: size, seed: number);
  @override
  Future<GeneratedPuzzle> daily(int day) async => PuzzleCatalog.dailyByKey(day);
  @override
  Future<PuzzleGame> preview(PuzzleGame game) async => game.previewHint();
  @override
  Future<PuzzleGame> restore(Map<String, Object?> json) async =>
      PuzzleGame.restore(json);
}
