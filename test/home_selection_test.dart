import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/feedback_scope.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/features/home/home_level_selector.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';

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

  testWidgets('selection animates and snaps at both ends with motion enabled', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    var selected = 4;
    final feedback = <FeedbackEvent>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            FeedbackScope(onFeedback: feedback.add, child: child!),
        home: StatefulBuilder(
          builder: (context, setState) => Center(
            child: HomeLevelSelector(
              selectedLevel: selected,
              unlockedThrough: 4,
              completedLevels: const {1, 2, 3},
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    final pager = find.byKey(const ValueKey('home level selector'));
    final pages = tester.widget<PageView>(pager).controller!;
    await tester.tap(find.bySemanticsLabel('Level 3, completed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(pages.page, inExclusiveRange(2, 3));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(pages.page, closeTo(2, .001));
    expect(feedback, [FeedbackEvent.selection]);
    feedback.clear();
    await tester.fling(pager, const Offset(900, 0), 1800);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(feedback, isNotEmpty);
    expect(feedback, everyElement(FeedbackEvent.uiClick));
    expect(pages.page, closeTo(0, .001));
    await tester.fling(pager, const Offset(-1000, 0), 1800);
    await tester.pumpAndSettle();
    expect(selected, 4);
    expect(pages.page, closeTo(3, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Next level during replay stays isolated until the latest unlocked level',
    (tester) async {
      final fixture = await _open(tester);
      final controller = fixture.container.read(puzzleGameProvider.notifier);
      await controller.openCampaignLevel(1);
      final puzzle = fixture.container
          .read(puzzleGameProvider)
          .game!
          .verifiedPuzzle;
      for (final (row, column) in puzzle.columnsByRow.indexed) {
        if ((row: row, column: column) ==
            fixture.container.read(puzzleSessionProvider)!.startingNova) {
          continue;
        }
        controller.play((row: row, column: column));
      }
      await controller.startNextLevel();
      expect(fixture.container.read(puzzleSessionProvider)!.level, 2);
      expect(
        fixture.container.read(puzzleGameProvider).campaign,
        same(fixture.campaign.game),
      );
      expect(fixture.container.read(puzzleGameProvider).unlockedThrough, 11);
      expect(
        fixture.container.read(puzzleGameProvider).completedLevels,
        fixture.campaign.completed,
      );
      await controller.saveCurrentProgress();
    },
  );

  for (final size in [
    const Size(360, 640),
    const Size(360, 740),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('Home uses safe height without scrolling on $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
      addTearDown(tester.view.reset);
      await _open(tester);
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('home vertical layout')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.maxScrollExtent, closeTo(0, 0.01));
      expect(find.text('How to play').hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.bySemanticsLabel('Settings')).dy,
        inInclusiveRange(36, 40),
      );
      expect(
        tester.getBottomRight(find.text('How to play')).dy,
        greaterThan(size.height - 80),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'selector snaps, updates labels and refuses the locked future level',
    (tester) async {
      final fixture = await _open(tester);
      expect(find.text('LEVEL 11'), findsOneWidget);
      expect(find.text('Play level 11'), findsOneWidget);
      final pager = find.byKey(const ValueKey('home level selector'));
      final pages = tester.widget<PageView>(pager).controller!;
      expect(pages.page, closeTo(10, 0.001));
      expect(
        find.bySemanticsLabel('Level 10, completed').hitTestable(),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 12, locked').hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('Level 12, locked'));
      await tester.fling(pager, const Offset(-700, 0), 1600);
      await tester.pumpAndSettle();
      expect(pages.page, closeTo(10, 0.001));
      expect(find.text('Play level 11'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Level 10, completed'));
      await tester.pumpAndSettle();
      expect(pages.page, closeTo(9, 0.001));
      expect(find.text('LEVEL 10'), findsOneWidget);
      expect(find.text('Play level 10'), findsOneWidget);

      await tester.drag(pager, const Offset(145, 0));
      await tester.pumpAndSettle();
      expect(pages.page!, lessThan(9));
      expect(pages.page, closeTo(pages.page!.roundToDouble(), 0.001));
      final selected = tester
          .widget<HomeLevelSelector>(find.byType(HomeLevelSelector))
          .selectedLevel;
      expect(find.text('Play level $selected'), findsOneWidget);
      final game = fixture.container.read(puzzleSessionProvider);
      expect(game, same(fixture.campaign.game.session));

      await expectLater(
        fixture.container
            .read(puzzleGameProvider.notifier)
            .openCampaignLevel(12),
        throwsRangeError,
      );
      expect(fixture.container.read(puzzleSessionProvider), same(game));
    },
  );

  testWidgets(
    'replay keeps campaign session and durable unlocks across every move and completion',
    (tester) async {
      final fixture = await _open(tester);
      final container = fixture.container;
      final journal = container.read(progressJournalProvider);
      final controller = container.read(puzzleGameProvider.notifier);
      final original = fixture.campaign.game.session.toJson();
      final campaignFiles = Map.of(fixture.storage.files);
      await tester.tap(find.bySemanticsLabel('Level 10, completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play level 10'));
      await tester.pumpAndSettle();
      expect(find.text('Level 10'), findsOneWidget);
      final replay = container.read(puzzleGameProvider).game!;
      final correct = (
        row: 0,
        column: replay.verifiedPuzzle.columnsByRow.first,
      );
      controller.play(correct);
      controller.play((row: 1, column: correct.column));
      final hint = (await controller.previewHint())!;
      controller.applyHint(hint);
      controller.undo();
      final progress = container.read(puzzleSessionProvider)!.toJson();
      await controller.saveCurrentProgress();
      expect(
        container.read(puzzleGameProvider).campaign!.session.toJson(),
        original,
      );
      expect(
        container.read(puzzleGameProvider).completedLevels,
        fixture.campaign.completed,
      );
      expect(container.read(puzzleGameProvider).unlockedThrough, 11);
      for (final key in campaignFiles.keys) {
        expect(fixture.storage.files[key], campaignFiles[key]);
      }
      final replaySave = await ProgressJournal(fixture.storage)
          .read('replay-10', PuzzleGame.restore);
      expect(replaySave!.session.toJson(), progress);
      final restored = await ProgressJournal(fixture.storage).read(
        CampaignProgress.key,
        (json) => CampaignProgress.decode(
          json,
          (json) async => PuzzleGame.restore(json),
        ),
      );
      expect(restored!.game.session.toJson(), original);

      controller.reset();
      await tester.pumpAndSettle();
      for (final (row, column) in replay.verifiedPuzzle.columnsByRow.indexed) {
        if ((row: row, column: column) ==
            container.read(puzzleSessionProvider)!.startingNova) {
          continue;
        }
        final cell = find.byKey(ValueKey((row: row, column: column)));
        await tester.ensureVisible(cell);
        await placeNova(tester, cell);
        await tester.pumpAndSettle();
      }
      expect(find.text('Beautifully done.'), findsOneWidget);
      await tester.tap(find.text('Next level'));
      await tester.pumpAndSettle();
      expect(container.read(puzzleSessionProvider)!.toJson(), original);
      await tester.ensureVisible(find.bySemanticsLabel('Back'));
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and leave'));
      await tester.pumpAndSettle();
      expect(find.text('Play level 11'), findsOneWidget);
      await journal.flush();
      expect(container.read(puzzleGameProvider).unlockedThrough, 11);
      expect(
        container.read(puzzleGameProvider).completedLevels,
        fixture.campaign.completed,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'returning Home defaults to latest unlocked and replay resumes independently',
    (tester) async {
      final fixture = await _open(tester);
      final controller = fixture.container.read(puzzleGameProvider.notifier);
      await tester.tap(find.bySemanticsLabel('Level 10, completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play level 10'));
      await tester.pumpAndSettle();
      controller.selectMode(PuzzleInputMode.markX);
      controller.play((row: 0, column: 0));
      final saved = fixture.container.read(puzzleSessionProvider)!;
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and leave'));
      await tester.pumpAndSettle();
      expect(find.text('Play level 11'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Level 10, completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play level 10'));
      await tester.pumpAndSettle();
      expect(
        fixture.container.read(puzzleSessionProvider)!.toJson(),
        saved.toJson(),
      );
      expect(
        fixture.container.read(puzzleGameProvider).campaign!.session.toJson(),
        fixture.campaign.game.session.toJson(),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<
  ({
    ProviderContainer container,
    CampaignProgress campaign,
    MemoryProgressStorage storage,
  })
>
_open(WidgetTester tester) async {
  final generated = PuzzleGenerator.generate(size: 4, seed: 11);
  var game = PuzzleGame.start(generated.puzzle, level: 11);
  game = game.play((row: 0, column: generated.puzzle.columnsByRow.first)).game;
  final campaign = CampaignProgress(
    game: game,
    completed: Set.unmodifiable(List.generate(10, (i) => i + 1)),
    unlockedThrough: 11,
  );
  final storage = MemoryProgressStorage();
  final journal = ProgressJournal(storage);
  await journal.write(CampaignProgress.key, campaign.toJson());
  final container = ProviderContainer(
    overrides: [
      campaignRestoreProvider.overrideWithValue(AsyncData(campaign)),
      progressJournalProvider.overrideWithValue(journal),
      puzzleWorkProvider.overrideWithValue(const _Work()),
      settingsStoreProvider.overrideWithValue(const _Settings()),
      audioServiceProvider.overrideWithValue(RecordingAudio()),
      hapticServiceProvider.overrideWithValue(RecordingHaptics()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NovaApp()),
  );
  await tester.pumpAndSettle();
  return (container: container, campaign: campaign, storage: storage);
}

class _Settings implements SettingsStore {
  const _Settings();
  @override
  Future<AppSettings> read() async => const AppSettings();
  @override
  Future<void> write(AppSettings settings) async {}
}

class _Work implements PuzzleWork {
  const _Work();
  @override
  Future<GeneratedPuzzle> level(int number) async =>
      PuzzleGenerator.generate(size: 4, seed: number);
  @override
  Future<GeneratedPuzzle> daily(int day) async => PuzzleCatalog.dailyByKey(day);
  @override
  Future<PuzzleGame> restore(Map<String, Object?> json) async =>
      PuzzleGame.restore(json);
  @override
  Future<PuzzleGame> preview(PuzzleGame game) async => game.previewHint();
}
