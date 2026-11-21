import 'package:novadoku/shared/widgets/nova_particle_backdrop.dart';
import 'package:novadoku/features/gameplay/gameplay_board.dart';
import 'package:novadoku/shared/widgets/nova_buttons.dart';
import 'package:novadoku/features/daily_challenge/daily_nova.dart';
import 'package:novadoku/features/gameplay/level_complete_nova.dart';
import 'package:novadoku/features/gameplay/try_again_nova.dart';
import 'package:novadoku/features/gameplay/gameplay_nova.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:novadoku/features/gameplay/gameplay_rewards.dart';
import 'package:novadoku/features/gameplay/gameplay_reward_effects.dart';
import 'package:novadoku/features/gameplay/gameplay_mistake_cell.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/router/app_router.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/features/gameplay/gameplay_screen.dart';
import 'package:novadoku/features/gameplay/gameplay_controls.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/shared/characters/nova_character.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';
import 'package:novadoku/core/theme/app_colors.dart';
import 'package:novadoku/features/gameplay/gameplay_cross.dart';
import 'package:novadoku/shared/widgets/nova_celebration.dart';
import 'package:novadoku/shared/dialogs/nova_modal.dart';

import 'support/feedback_fakes.dart';
import 'support/gameplay_gestures.dart';

import 'package:novadoku/features/gameplay/gameplay_region_progress.dart';

void main() {
  testWidgets(
    'third mistake spends attempt and sounds now, then finishes before Try Again',
    (tester) async {
      final audio = RecordingAudio();
      final container = await _open(tester, reduced: false, audio: audio);
      final game = container.read(puzzleGameProvider).game!;
      final wrong = [
        for (var row = 0; row < 4; row++)
          for (var column = 0; column < 4; column++) (row: row, column: column),
      ].where((cell) => !game.verifiedPuzzle.isNova(cell)).take(3).toList();
      for (var i = 0; i < 3; i++) {
        await placeNova(tester, _cell(wrong[i]));
        expect(_session(container).attemptsRemaining, 2 - i);
        expect(
          audio.events.last,
          i == 2 ? FeedbackEvent.failure : FeedbackEvent.mistake,
        );
      }
      final snapshot = _session(container).toJson();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('One more try?'), findsNothing);
      expect(_session(container).status, PuzzleStatus.failed);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('One more try?'), findsNothing);
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('One more try?'), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await _settle(tester);
      expect(find.text('One more try?'), findsOneWidget);
      expect(_session(container).toJson(), snapshot);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'perfect clear is brief before the original outcome and progress is already saved',
    (tester) async {
      final container = await _open(tester, reduced: false);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final cells = puzzle.columnsByRow.indexed
          .map((e) => (row: e.$1, column: e.$2))
          .where((cell) => cell != _session(container).startingNova)
          .toList();
      for (final cell in cells.take(cells.length - 1)) {
        await _tap(tester, _cell(cell));
      }
      await placeNova(tester, _cell(cells.last));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_session(container).status, PuzzleStatus.completed);
      expect(container.read(puzzleGameProvider).unlockedThrough, 2);
      expect(find.text('PERFECT CLEAR!'), findsNWidgets(2));
      expect(find.text('FLAWLESS!'), findsOneWidget);
      expect(find.text('Beautifully done.'), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(find.text('Beautifully done.'), findsOneWidget);
      expect(find.byType(NovaCelebration), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'player-only combos, second-heart burst and banner keep gameplay fixed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
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
      final container = await _open(tester, size: 6, reduced: false);
      await tester.runAsync(() async {
        await Future.wait([
          precacheImage(
            NovaArtwork.grid.image,
            tester.element(find.byType(GameplayScreen)),
          ),
          precacheImage(
            const AssetImage('assets/characters/nova/nova_gameplay_still.webp'),
            tester.element(find.byType(GameplayScreen)),
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final playback = tester.state(find.byType(GameplayNovaPlayback));
      Future<void> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find
              .ancestor(
                of: find.byType(GameplayScreen),
                matching: find.byType(RepaintBoundary),
              )
              .first,
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/gameplay_rewards')
            ..createSync(recursive: true);
          File('${dir.path}/$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      GameplayNotice? notice() => tester
          .widget<GameplayPraiseOverlay>(find.byType(GameplayPraiseOverlay))
          .notices
          .value;
      CellPosition remaining() => puzzle.columnsByRow.indexed
          .map((entry) => (row: entry.$1, column: entry.$2))
          .firstWhere(
            (cell) => _session(container).marks[cell] != CellMark.nova,
          );
      await placeNova(tester, _cell(remaining()));
      await tester.pump(const Duration(milliseconds: 200));
      expect(notice()!.title, GameplayPraise.nice);
      await capture('combo');
      tester.widget<GameplayControls>(find.byType(GameplayControls)).onNova!();
      await tester.pump();
      await placeNova(tester, _cell(remaining()));
      await tester.pump(const Duration(milliseconds: 200));
      expect(notice()!.title, GameplayPraise.great);
      for (var mistake = 0; mistake < 2; mistake++) {
        final cell =
            [
              for (var row = 0; row < 6; row++)
                for (var column = 0; column < 6; column++)
                  (row: row, column: column),
            ].firstWhere(
              (cell) =>
                  !puzzle.isNova(cell) &&
                  !_session(container).rejectedCells.contains(cell),
            );
        await placeNova(tester, _cell(cell));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_session(container).attemptsRemaining, 1);
      expect(notice(), isNull);
      expect(find.byType(GameplayHeartBreak), findsOneWidget);
      expect(find.byType(GameplayMistakeCell), findsNWidgets(2));
      final boardRect = tester.getRect(find.byType(GameplayBoard));
      final controlsRect = tester.getRect(find.byType(GameplayControls));
      final snapshot = _session(container).toJson();
      await capture('second-mistake');
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);
      expect(tester.getRect(find.byType(GameplayBoard)), boardRect);
      expect(tester.getRect(find.byType(GameplayControls)), controlsRect);
      expect(_session(container).toJson(), snapshot);
      expect(tester.state(find.byType(GameplayNovaPlayback)), same(playback));
      await placeNova(tester, _cell(remaining()));
      await tester.pump();
      expect(notice()!.title, GameplayPraise.nice);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'X audio follows tap add/remove and swipe add/remove immediately',
    (tester) async {
      final audio = RecordingAudio();
      final container = await _open(tester, audio: audio);
      const cell = (row: 0, column: 0);
      await tester.tap(_cell(cell));
      expect(_session(container).marks[cell], CellMark.cross);
      expect(audio.events, [FeedbackEvent.markX]);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.tap(_cell(cell));
      expect(_session(container).marks[cell], isNull);
      expect(audio.events, [FeedbackEvent.markX, FeedbackEvent.markX]);
      await tester.pump(const Duration(milliseconds: 301));
      final first = tester.getCenter(_cell(cell));
      final last = tester.getCenter(_cell((row: 0, column: 3)));
      await tester.dragFrom(first, last - first);
      expect(audio.events.skip(2), List.filled(4, FeedbackEvent.markXSwipe));
      await _settle(tester);
      await tester.dragFrom(last, first - last);
      expect(audio.events.skip(2), List.filled(8, FeedbackEvent.markXSwipe));
      for (var column = 0; column < 4; column++) {
        expect(_session(container).marks[(row: 0, column: column)], isNull);
      }
      await _settle(tester);
      final count = audio.events.length;
      await tester.tap(_cell(_session(container).startingNova!));
      expect(audio.events, hasLength(count));
    },
  );

  testWidgets(
    'tile reuse preserves live marks, preferences and translated semantics',
    (tester) async {
      final container = await _open(tester, size: 6);
      const target = (row: 0, column: 0);
      const untouched = (row: 2, column: 2);
      final original = tester.widget<NovaGridCell>(_cell(untouched));
      await markCell(tester, _cell(target));
      expect(tester.widget<NovaGridCell>(_cell(untouched)), same(original));
      expect(_session(container).marks[target], CellMark.cross);
      final settings = container.read(appSettingsProvider.notifier);
      await settings.saveChanges((s) => s.copyWith(regionPatterns: true));
      await _settle(tester);
      final patterned = tester.widget<NovaGridCell>(_cell(untouched));
      expect(patterned.showRegionPattern, isTrue);
      expect(patterned, isNot(same(original)));
      await settings.saveChanges(
        (s) => s.copyWith(language: AppLanguage.hindi),
      );
      await _settle(tester);
      final translated = tester.widget<NovaGridCell>(_cell(untouched));
      expect(translated.semanticLabel, isNot(patterned.semanticLabel));
      expect(_session(container).marks[target], CellMark.cross);
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await _settle(tester);
      expect(tester.takeException(), isNull);
    },
  );

  for (var size = 4; size <= 10; size++) {
    testWidgets(
      'stress $size with original feedback, animations and lifecycle',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final audio = RecordingAudio();
        final container = await _open(
          tester,
          size: size,
          reduced: false,
          audio: audio,
          progress: ProgressJournal(MemoryProgressStorage()),
        );
        final given = _session(container).startingNova!;
        final clock = Stopwatch()..start();
        for (var i = 0; i < 120; i++) {
          await tester.tap(_cell((row: 0, column: i % 2)));
          await tester.pump(const Duration(milliseconds: 8));
        }
        final first = tester.getCenter(_cell((row: 0, column: 0)));
        final last = tester.getCenter(_cell((row: 0, column: size - 1)));
        for (var stroke = 0; stroke < 20; stroke++) {
          final gesture = await tester.startGesture(first);
          for (var step = 1; step <= 8; step++) {
            await gesture.moveTo(Offset.lerp(first, last, step / 8)!);
            await tester.pump(const Duration(milliseconds: 8));
          }
          await gesture.moveTo(first);
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 8));
        }
        await _settle(tester);
        clock.stop();
        expect(_session(container).marks, {given: CellMark.nova});
        expect(_session(container).history, hasLength(120 + 20 * size));
        expect(_session(container).attemptsRemaining, 3);
        expect(_session(container).hintsRemaining, 3);
        expect(_session(container).novaUsesRemaining, 4);
        expect(audio.events, isNotEmpty);
        expect(audio.events.every((event) => event.isXMark), isTrue);
        final beforePause = _session(container);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(audio.configurations.last, (music: false, effects: false));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _settle(tester);
        expect(_session(container), same(beforePause));
        await container.read(puzzleGameProvider.notifier).saveCurrentProgress();
        debugPrint(
          'Host stress ${size}x$size: 120 taps + 20 strokes, '
          '${clock.elapsedMilliseconds} ms host wall time; supplied X cue only',
        );
        await tester.tap(_cell((row: 0, column: 0)));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Nova charges and automatic hint changes persist, and Reset refills both',
    (tester) async {
      final storage = MemoryProgressStorage();
      final container = await _open(
        tester,
        size: 6,
        progress: ProgressJournal(storage),
      );
      for (var use = 0; use < 4; use++) {
        await _tap(tester, find.text('Nova'));
        expect(_session(container).novaUsesRemaining, 3 - use);
      }
      final exhausted = _session(container);
      await _tap(tester, find.text('Nova'));
      expect(_session(container), same(exhausted));
      expect(find.text('Undo'), findsNothing);
      await _useHint(tester);
      await container.read(puzzleGameProvider.notifier).saveCurrentProgress();
      final saved = await ProgressJournal(storage).read(
        CampaignProgress.key,
        (data) => CampaignProgress.decode(data, const _TestWork(6).restore),
      );
      expect(saved!.game.session.novaUsesRemaining, 0);
      expect(saved.game.session.hintsRemaining, 2);
      expect(saved.game.session.toJson(), _session(container).toJson());
      await _reset(tester);
      expect(_session(container).novaUsesRemaining, 4);
      expect(_session(container).hintsRemaining, 3);
      expect(_session(container).attemptsRemaining, 3);
    },
  );

  testWidgets(
    'Gameplay hides region numbers and uses larger Nova and white X marks',
    (tester) async {
      final container = await _open(tester);
      final given = _session(container).startingNova!;
      final nova = tester.widget<NovaGridCell>(_cell(given));
      expect(nova.markFraction, greaterThan(.8));
      expect(nova.showRegionLabel, isFalse);
      for (final cell in tester.widgetList<NovaGridCell>(
        find.byType(NovaGridCell),
      )) {
        expect(cell.showRegionLabel, isFalse);
        expect(
          find.descendant(
            of: find.byKey(cell.key!),
            matching: find.text(cell.regionLabel),
          ),
          findsNothing,
        );
      }
      const target = (row: 0, column: 0);
      await markCell(tester, _cell(target));
      final cross = tester.widget<GameplayCross>(
        find.descendant(
          of: _cell(target),
          matching: find.byType(GameplayCross),
        ),
      );
      expect(cross.color, AppColors.surface);
    },
  );

  testWidgets(
    'reset cancellation ends a double-tap window without changing the board',
    (tester) async {
      final container = await _open(tester);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final correct = (row: 0, column: puzzle.columnsByRow.first);
      await tester.tap(_cell(correct));
      await tester.pump();
      final before = _session(container);
      await _tap(tester, find.text('Reset'));
      await _tap(tester, find.text('Cancel'));
      expect(_session(container), same(before));
      await tester.tap(_cell(correct));
      await _settle(tester);
      expect(_session(container).marks[correct], isNull);
      expect(_session(container).novasPlaced, 1);
    },
  );

  testWidgets('one rule card glows once on entry and honors reduced motion', (
    tester,
  ) async {
    Future<void> open(bool reduced) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const Center(
            child: SizedBox(width: 354, child: GameplayRules()),
          ),
        ),
      ),
    );
    double borderAlpha() =>
        ((tester
                            .widget<DecoratedBox>(
                              find.byKey(const ValueKey('gameplay rule card')),
                            )
                            .decoration
                        as BoxDecoration)
                    .border!
                as Border)
            .top
            .color
            .a;
    await open(false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(borderAlpha(), greaterThan(0));
    await _settle(tester);
    expect(borderAlpha(), 0);
    await tester.pumpWidget(const SizedBox());
    await open(true);
    expect(borderAlpha(), 0);
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fast diagonal swipe covers a ten by ten board without Nova attempts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final container = await _open(tester, size: 10);
      final first = tester.getCenter(_cell((row: 0, column: 0)));
      final last = tester.getCenter(_cell((row: 9, column: 9)));
      final gesture = await tester.startGesture(first);
      await gesture.moveTo(last);
      await gesture.moveTo(first);
      await gesture.up();
      await _settle(tester);
      for (var index = 0; index < 10; index++) {
        final cell = (row: index, column: index);
        expect(
          _session(container).marks[cell],
          cell == _session(container).startingNova
              ? CellMark.nova
              : CellMark.cross,
        );
      }
      expect(_session(container).attemptsRemaining, 3);
      expect(_session(container).novasPlaced, 1);
      expect(
        _session(container).marks.length,
        _session(container).startingNova!.row ==
                _session(container).startingNova!.column
            ? 10
            : 11,
      );
      expect(_session(container).rejectedCells, isEmpty);
    },
  );

  testWidgets(
    'swipe selects add or erase once and keeps that mode on reversal',
    (tester) async {
      final container = await _open(tester);
      await markCell(tester, _cell((row: 0, column: 1)));
      final first = tester.getCenter(_cell((row: 0, column: 0)));
      final last = tester.getCenter(_cell((row: 0, column: 3)));
      final gesture = await tester.startGesture(first);
      await gesture.moveTo(last);
      await tester.pump();
      await gesture.moveTo(first);
      await gesture.moveTo(last);
      await gesture.up();
      await _settle(tester);
      for (var column = 0; column < 4; column++) {
        expect(
          _session(container).marks[(row: 0, column: column)],
          CellMark.cross,
        );
      }
      expect(_session(container).history, hasLength(4));
      expect(_session(container).attemptsRemaining, 3);
      expect(_session(container).hintsRemaining, 3);
      await tester.dragFrom(last, first - last);
      await _settle(tester);
      for (var column = 0; column < 4; column++) {
        expect(_session(container).marks[(row: 0, column: column)], isNull);
      }
      expect(_session(container).history, hasLength(8));
    },
  );

  testWidgets(
    'red X and starting Nova survive taps, double taps, swipes and undo',
    (tester) async {
      final container = await _open(tester);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final wrong = (row: 0, column: (puzzle.columnsByRow.first + 1) % 4);
      await _tap(tester, _cell(wrong));
      final before = _session(container);
      await markCell(tester, _cell(wrong));
      await _tap(tester, _cell(wrong));
      expect(_session(container), same(before));
      final first = tester.getCenter(_cell((row: 0, column: 0)));
      final last = tester.getCenter(_cell((row: 0, column: 3)));
      await tester.dragFrom(first, last - first);
      await _settle(tester);
      while (_session(container).history.isNotEmpty) {
        await _undo(tester, container);
      }
      expect(_session(container).marks, {
        before.startingNova!: CellMark.nova,
        wrong: CellMark.cross,
      });
      expect(_session(container).attemptsRemaining, 2);
      final given = before.startingNova!;
      await markCell(tester, _cell(given));
      await _tap(tester, _cell(given));
      final start = tester.getCenter(_cell((row: 3, column: 0)));
      final end = tester.getCenter(_cell((row: 3, column: 3)));
      await tester.dragFrom(start, end - start);
      await _settle(tester);
      expect(_session(container).marks[given], CellMark.nova);
      await _reset(tester);
      expect(_session(container).marks, {given: CellMark.nova});
      expect(_session(container).startingNova, given);
      expect(_session(container).rejectedCells, isEmpty);
    },
  );

  testWidgets('multi-touch and cancelled drags do not create Nova attempts', (
    tester,
  ) async {
    final container = await _open(tester);
    final before = _session(container);
    final first = await tester.startGesture(
      tester.getCenter(_cell((row: 0, column: 0))),
      pointer: 1,
    );
    final second = await tester.startGesture(
      tester.getCenter(_cell((row: 1, column: 0))),
      pointer: 2,
    );
    await first.moveBy(const Offset(80, 0));
    await second.moveBy(const Offset(80, 0));
    await second.up();
    await first.cancel();
    await _settle(tester);
    expect(_session(container), same(before));
  });

  testWidgets(
    'single and double taps are exclusive and save their exact edits',
    (tester) async {
      final audio = RecordingAudio();
      final storage = MemoryProgressStorage();
      final container = await _open(
        tester,
        audio: audio,
        progress: ProgressJournal(storage),
      );
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final correct = (row: 0, column: puzzle.columnsByRow.first);
      final wrong = (row: 1, column: correct.column);

      await tester.tap(_cell(correct));
      expect(_session(container).marks[correct], CellMark.cross);
      expect(audio.events, [FeedbackEvent.markX]);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(_cell(correct));
      await _settle(tester);
      expect(_session(container).marks, {
        _session(container).startingNova!: CellMark.nova,
        correct: CellMark.nova,
      });
      expect(_session(container).history, hasLength(1));
      expect(audio.events, [FeedbackEvent.markX, FeedbackEvent.placement]);

      await markCell(tester, _cell(wrong));
      expect(_session(container).marks[wrong], CellMark.cross);
      expect(_session(container).attemptsRemaining, 3);
      await markCell(tester, _cell(wrong));
      expect(_session(container).marks[wrong], isNull);
      final edits = _session(container).history.length;
      await _tap(tester, _cell(wrong));
      expect(_session(container).marks[wrong], CellMark.cross);
      expect(_session(container).rejectedCells, contains(wrong));
      expect(_session(container).attemptsRemaining, 2);
      expect(_session(container).history, hasLength(edits));
      final redCross =
          tester.widget<NovaGridCell>(_cell(wrong)).mark! as GameplayCross;
      expect(redCross.color, AppColors.error);
      expect(audio.events, [
        FeedbackEvent.markX,
        FeedbackEvent.placement,
        FeedbackEvent.markX,
        FeedbackEvent.markX,
        FeedbackEvent.markX,
        FeedbackEvent.mistake,
      ]);

      final before = _session(container);
      await markCell(tester, _cell(correct));
      await _tap(tester, _cell(correct));
      expect(_session(container), same(before));
      await container.read(puzzleGameProvider.notifier).saveCurrentProgress();
      final restored = await ProgressJournal(storage).read(
        CampaignProgress.key,
        (data) => CampaignProgress.decode(data, const _TestWork(4).restore),
      );
      expect(restored!.game.session.toJson(), before.toJson());
    },
  );

  testWidgets(
    'double tapping an X replaces it with Nova without another X edit',
    (tester) async {
      final container = await _open(tester);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final target = (row: 0, column: puzzle.columnsByRow.first);
      await markCell(tester, _cell(target));
      await _tap(tester, _cell(target));
      expect(_session(container).marks[target], CellMark.nova);
      expect(_session(container).history, hasLength(2));
      await _undo(tester, container);
      expect(_session(container).marks[target], CellMark.cross);
      expect(
        tester
            .widgetList<GameplayRegionIcon>(find.byType(GameplayRegionIcon))
            .where((icon) => icon.completed),
        hasLength(1),
      );
    },
  );

  testWidgets('instant single tap survives Settings without a delayed edit', (
    tester,
  ) async {
    final container = await _open(tester);
    await tester.tap(_cell((row: 0, column: 0)));
    final tapped = _session(container);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));
    expect(_session(container), same(tapped));
    await _tap(tester, find.bySemanticsLabel('Close'));
    expect(_session(container), same(tapped));
  });

  for (var size = 4; size <= 10; size++) {
    testWidgets(
      'region progress follows actual board colors and edits at size $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
        addTearDown(tester.view.reset);
        final container = await _open(tester, size: size);
        void verify() {
          final session = _session(container);
          final icons = tester
              .widgetList<GameplayRegionIcon>(find.byType(GameplayRegionIcon))
              .toList();
          expect(icons, hasLength(size));
          for (final icon in icons) {
            final regionCell = tester
                .widgetList<NovaGridCell>(find.byType(NovaGridCell))
                .firstWhere((cell) => cell.regionLabel == '${icon.region}');
            expect(icon.tone, regionCell.region);
            expect(
              icon.completed,
              session.marks.entries.any(
                (entry) =>
                    entry.value == CellMark.nova &&
                    session.puzzle.regionAt(entry.key) == icon.region,
              ),
            );
          }
        }

        verify();
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        expect(
          scroll.maxScrollExtent,
          0,
          reason: 'standard phones should fit the full board and actions',
        );
        final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
        await _tap(tester, _cell((row: 0, column: puzzle.columnsByRow.first)));
        verify();
        await _tap(tester, _cell((row: 1, column: puzzle.columnsByRow.first)));
        expect(
          scroll.maxScrollExtent,
          0,
          reason: 'mistake feedback should also fit',
        );
        expect(find.text('Reset').hitTestable(), findsOneWidget);
        verify();
        await _undo(tester, container);
        verify();
        await _useHint(tester);
        verify();
        await _reset(tester);
        verify();
        expect(_session(container).marks, {
          _session(container).startingNova!: CellMark.nova,
        });
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'real placement, X, mistake feedback, undo and reset update the board',
    (tester) async {
      final container = await _open(tester);
      final board = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final correct = (row: 0, column: board.columnsByRow.first);
      final wrong = (row: 1, column: correct.column);
      final cross = (
        row: 0,
        column: (correct.column + 1) % board.definition.size,
      );
      expect(
        tester
            .widgetList<GameplayRegionIcon>(find.byType(GameplayRegionIcon))
            .where((icon) => icon.completed),
        hasLength(1),
      );
      expect(find.text('Place Nova'), findsNothing);
      expect(find.text('Mark X'), findsNothing);
      expect(find.text('Find the Novas'), findsNothing);
      expect(find.text('3 attempts left'), findsOneWidget);

      await _tap(tester, _cell(correct));
      expect(_session(container).marks[correct], CellMark.nova);
      expect(
        tester
            .widgetList<GameplayRegionIcon>(find.byType(GameplayRegionIcon))
            .where((icon) => icon.completed),
        hasLength(2),
      );
      await markCell(tester, _cell(cross));
      expect(_session(container).marks[cross], CellMark.cross);
      await _tap(tester, _cell(wrong));
      expect(_session(container).marks[wrong], CellMark.cross);
      expect(find.text('2 attempts left'), findsOneWidget);
      expect(find.text('Try another square.'), findsNothing);
      expect(find.text('Try another sequence'), findsNothing);
      expect(find.byKey(const ValueKey('mistake banner')), findsNothing);
      expect(
        tester.widget<NovaGridCell>(_cell(wrong)).appearance,
        NovaCellAppearance.mistake,
      );
      expect(find.byType(NovaCharacter), findsNothing);

      await _undo(tester, container);
      expect(_session(container).marks[cross], isNull);
      expect(_session(container).marks[wrong], CellMark.cross);
      expect(_session(container).marks[correct], CellMark.nova);
      expect(_session(container).attemptsRemaining, 2);
      expect(find.text('Try another square.'), findsNothing);
      await _reset(tester);
      expect(_session(container).puzzle, same(board.definition));
      expect(_session(container).marks, {
        _session(container).startingNova!: CellMark.nova,
      });
      expect(_session(container).attemptsRemaining, 3);
      expect(_session(container).mode, PuzzleInputMode.placeNova);
    },
  );

  testWidgets(
    'automatic hints mark a limited group, use one charge, and stop at zero',
    (tester) async {
      final container = await _open(tester, size: 6);
      final before = _session(container);
      await _useHint(tester);
      expect(_session(container).hintsRemaining, 2);
      expect(_session(container).novaUsesRemaining, 4);
      expect(
        _session(container).marks.length - before.marks.length,
        inInclusiveRange(1, 4),
      );
      expect(find.byType(NovaBottomSheet), findsNothing);
      await _useHint(tester);
      await _useHint(tester);
      expect(_session(container).hintsRemaining, 0);
      final exhausted = _session(container);
      await _useHint(tester);
      expect(_session(container), same(exhausted));
    },
  );

  testWidgets(
    'reset confirmation restores the given, budgets and both power-ups',
    (tester) async {
      final container = await _open(tester, size: 6);
      await _tap(tester, find.text('Nova'));
      await _useHint(tester);
      final before = _session(container);
      expect(before.novaUsesRemaining, 3);
      expect(before.hintsRemaining, 2);
      await _tap(tester, find.text('Reset'));
      await _tap(tester, find.text('Cancel'));
      expect(_session(container), same(before));
      await _reset(tester);
      expect(_session(container).marks, {before.startingNova!: CellMark.nova});
      expect(_session(container).hintsRemaining, 3);
      expect(_session(container).novaUsesRemaining, 4);
      expect(_session(container).attemptsRemaining, 3);
      expect(_session(container).history, isEmpty);
    },
  );

  testWidgets(
    'runs out of attempts, retries, completes the same puzzle and opens the next',
    (tester) async {
      final container = await _open(tester);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      for (var i = 0; i < PuzzleSession.startingAttempts; i++) {
        final bad = (
          row: i,
          column: (puzzle.columnsByRow[i] + 1) % puzzle.definition.size,
        );
        await _tap(tester, _cell(bad));
      }
      expect(_session(container).status, PuzzleStatus.failed);
      expect(find.text('One more try?'), findsOneWidget);
      expect(find.text('A FRESH START'), findsOneWidget);
      expect(find.byType(TryAgainNova), findsOneWidget);
      await _tap(tester, find.text('Try again'));
      expect(_session(container).puzzle, same(puzzle.definition));
      expect(_session(container).attemptsRemaining, 3);

      for (final (row, column) in puzzle.columnsByRow.indexed) {
        if ((row: row, column: column) ==
            container.read(puzzleSessionProvider)!.startingNova) {
          continue;
        }
        await _tap(tester, _cell((row: row, column: column)));
      }
      expect(_session(container).status, PuzzleStatus.completed);
      expect(find.text('Beautifully done.'), findsOneWidget);
      expect(find.text('PUZZLE COMPLETE'), findsOneWidget);
      expect(find.byType(LevelCompleteNova), findsOneWidget);
      await _tap(tester, find.text('Next level'));
      expect(find.text('Level 2'), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .queryParameters['level'],
        '2',
      );
      expect(_session(container).status, PuzzleStatus.playing);
      expect(_session(container).marks, {
        _session(container).startingNova!: CellMark.nova,
      });
    },
  );

  testWidgets(
    'settings returns to the puzzle and leaving retains its session',
    (tester) async {
      final container = await _open(tester);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      await _tap(tester, _cell((row: 0, column: puzzle.columnsByRow.first)));
      final played = _session(container);
      await _tap(tester, find.bySemanticsLabel('Settings'));
      expect(find.text('Make it feel like you.'), findsOneWidget);
      await _tap(tester, find.bySemanticsLabel('Close'));
      expect(find.byType(GameplayScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.text('Take a break?'), findsOneWidget);
      await _tap(tester, find.text('Keep playing'));
      expect(_session(container), same(played));
      await _tap(tester, find.bySemanticsLabel('Back'));
      await _tap(tester, find.text('Save and leave'));
      expect(find.text('Play level 1'), findsOneWidget);
      await _tap(tester, find.text('Play level 1'));
      expect(_session(container), same(played));
      expect(find.byType(GameplayScreen), findsOneWidget);
    },
  );

  testWidgets('Save and leave waits for the campaign write before navigating', (
    tester,
  ) async {
    final storage = _SlowProgressStorage();
    final container = await _open(tester, progress: ProgressJournal(storage));
    final game = container.read(puzzleGameProvider).game!;
    final cell = (row: 0, column: game.verifiedPuzzle.columnsByRow.first);
    storage.gate = Completer<void>();
    await _tap(tester, _cell(cell));
    await _tap(tester, find.bySemanticsLabel('Back'));
    await _tap(tester, find.text('Save and leave'));
    expect(find.byType(GameplayScreen), findsOneWidget);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/play',
    );

    storage.gate!.complete();
    await _settle(tester);
    expect(find.text('Play level 1'), findsOneWidget);
    final restored = await ProgressJournal(storage).read(
      CampaignProgress.key,
      (data) => CampaignProgress.decode(data, const _TestWork(4).restore),
    );
    expect(restored!.game.session.marks[cell], CellMark.nova);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily progress and completion remain independent of campaign', (
    tester,
  ) async {
    final container = await _open(tester);
    final campaign = container.read(puzzleGameProvider).game!.verifiedPuzzle;
    await _tap(tester, _cell((row: 0, column: campaign.columnsByRow.first)));
    final campaignProgress = _session(container);
    await _tap(tester, find.bySemanticsLabel('Back'));
    await _tap(tester, find.text('Save and leave'));

    await _tap(tester, find.text('Daily challenge'));
    expect(find.text('DAILY PLAY'), findsOneWidget);
    expect(find.byType(DailyNova), findsOneWidget);
    await _tap(tester, find.text('Play daily puzzle'));
    final daily = container.read(puzzleGameProvider).game!.verifiedPuzzle;
    expect(_session(container).dailyDay, isNotNull);
    expect(_session(container).level, isNull);
    await _tap(tester, _cell((row: 0, column: daily.columnsByRow.first)));
    final dailyProgress = _session(container);

    await _tap(tester, find.bySemanticsLabel('Settings'));
    await _tap(tester, find.bySemanticsLabel('Region patterns'));
    await _tap(tester, find.text('How to play'));
    expect(find.text('Rows + columns'), findsOneWidget);
    expect(find.text('Every region'), findsOneWidget);
    expect(find.text('Never touching'), findsOneWidget);
    await _tap(tester, find.text('Let’s play'));
    expect(_session(container), same(dailyProgress));
    expect(
      tester
          .widget<NovaGridCell>(find.byType(NovaGridCell).first)
          .showRegionPattern,
      isTrue,
    );

    await _tap(tester, find.bySemanticsLabel('Back'));
    await _tap(tester, find.text('Save and leave'));
    expect(find.text('Play daily puzzle'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Back'));
    await _tap(tester, find.text('Play level 1'));
    expect(_session(container), same(campaignProgress));
    await _tap(tester, find.bySemanticsLabel('Back'));
    await _tap(tester, find.text('Save and leave'));

    await _tap(tester, find.text('Daily challenge'));
    await _tap(tester, find.text('Play daily puzzle'));
    expect(_session(container), same(dailyProgress));
    for (final (row, column) in daily.columnsByRow.indexed.skip(1)) {
      if ((row: row, column: column) == _session(container).startingNova) {
        continue;
      }
      await _tap(tester, _cell((row: row, column: column)));
    }
    expect(_session(container).status, PuzzleStatus.completed);
    expect(find.text('Beautifully done.'), findsOneWidget);
    expect(find.text('Next level'), findsNothing);
    expect(container.read(campaignLevelProvider), 1);
    await _tap(tester, find.text('Back home'));
    await _tap(tester, find.text('Play level 1'));
    expect(_session(container), same(campaignProgress));
  });

  testWidgets(
    'renders ten regions and scrollable controls on a compact enlarged-text viewport',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 550);
      tester.view.padding = const FakeViewPadding(top: 40, bottom: 30);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await _open(tester, size: 10, level: 25);
      expect(_session(container).puzzle.size, 10);
      final cells = tester.widgetList<NovaGridCell>(find.byType(NovaGridCell));
      expect(cells, hasLength(100));
      expect(cells.map((tile) => tile.region).toSet(), hasLength(10));
      await markCell(tester, _cell((row: 9, column: 9)));
      expect(_session(container).marks[(row: 9, column: 9)], CellMark.cross);
      await _undo(tester, container);
      expect(_session(container).marks, {
        _session(container).startingNova!: CellMark.nova,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gameplay sends one cue per move, hint and outcome', (
    tester,
  ) async {
    final audio = RecordingAudio();
    final haptics = RecordingHaptics();
    final container = await _open(tester, audio: audio, haptics: haptics);
    final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
    final column = puzzle.columnsByRow.first;
    final cross = (row: 0, column: (column + 1) % puzzle.definition.size);
    await _tap(tester, _cell((row: 0, column: column)));
    await markCell(tester, _cell(cross));
    await _tap(tester, _cell((row: 1, column: column)));
    await _useHint(tester);
    for (final (row, solution) in puzzle.columnsByRow.indexed.skip(1)) {
      if ((row: row, column: solution) == _session(container).startingNova) {
        continue;
      }
      await _tap(tester, _cell((row: row, column: solution)));
    }
    expect(audio.events.where((event) => event.priority > 0), [
      FeedbackEvent.markX,
      FeedbackEvent.placement,
      FeedbackEvent.markX,
      FeedbackEvent.markX,
      FeedbackEvent.mistake,
      FeedbackEvent.hint,
      FeedbackEvent.markX,
      FeedbackEvent.placement,
      FeedbackEvent.markX,
      FeedbackEvent.victory,
    ]);
    expect(
      haptics.cues,
      containsAll([
        HapticCue.light,
        HapticCue.success,
        HapticCue.error,
        HapticCue.medium,
      ]),
    );
    expect(haptics.cues.length, lessThanOrEqualTo(audio.events.length));
    expect(find.byType(NovaCelebration), findsOneWidget);
    expect(find.byKey(const ValueKey('victory particles')), findsNothing);

    await _tap(tester, find.text('Next level'));
    final next = container.read(puzzleGameProvider).game!.verifiedPuzzle;
    for (var attempt = 0; attempt < 3; attempt++) {
      final bad = (
        row: attempt,
        column: (next.columnsByRow[attempt] + 1) % next.definition.size,
      );
      await _tap(tester, _cell(bad));
    }
    expect(
      audio.events
          .where((event) => event.priority > 0 && !event.isXMark)
          .toList()
          .reversed
          .take(3),
      [FeedbackEvent.failure, FeedbackEvent.mistake, FeedbackEvent.mistake],
    );
    expect(find.byType(NovaCelebration), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  for (var size = 4; size <= 10; size++) {
    for (final reduced in [false, true]) {
      testWidgets(
        'hint overlay keeps layout fixed at size $size, reduced $reduced',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
          tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
          addTearDown(tester.view.reset);
          final container = await _open(tester, size: size, reduced: reduced);
          final scroll = tester
              .state<ScrollableState>(
                find
                    .descendant(
                      of: find.byType(GameplayScreen),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position;
          final targets = [
            find.byType(GameplayBoard),
            find.byType(GameplayControls),
            find.text('Level 1'),
            _cell((row: 0, column: 0)),
            _cell((row: size - 1, column: size - 1)),
          ];
          final original = targets.map(tester.getRect).toList();
          final offset = scroll.pixels;
          final extent = scroll.maxScrollExtent;
          void fixed() {
            expect(scroll.pixels, offset);
            expect(scroll.maxScrollExtent, extent);
            expect(targets.map(tester.getRect).toList(), original);
          }

          for (final confirm in [false, true]) {
            final before = _session(container);
            tester
                .widget<GameplayControls>(find.byType(GameplayControls))
                .onHint!();
            await tester.pump();
            fixed();
            await tester.pump(const Duration(milliseconds: 120));
            fixed();
            await tester.pump(const Duration(milliseconds: 400));
            fixed();
            expect(find.byType(NovaBottomSheet), findsOneWidget);
            expect(_session(container), same(before));
            await tester.dragFrom(const Offset(8, 110), const Offset(0, -70));
            await tester.pump(const Duration(milliseconds: 100));
            fixed();
            await tester.tap(find.text(confirm ? 'Apply hint' : 'Cancel'));
            await tester.pump();
            fixed();
            await tester.pump(const Duration(milliseconds: 100));
            fixed();
            await tester.pump(const Duration(milliseconds: 400));
            fixed();
            expect(find.byType(NovaBottomSheet), findsNothing);
            expect(
              _session(container).hintsRemaining,
              before.hintsRemaining - (confirm ? 1 : 0),
            );
          }
        },
      );
    }
  }

  testWidgets(
    'hint overlay stops an in-flight background scroll without moving it',
    (tester) async {
      await _open(tester, size: 10);
      final scroll = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(GameplayScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(scroll.maxScrollExtent, greaterThan(0));
      unawaited(
        scroll.animateTo(
          scroll.maxScrollExtent,
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final offset = scroll.pixels;
      final extent = scroll.maxScrollExtent;
      tester.widget<GameplayControls>(find.byType(GameplayControls)).onHint!();
      await _settle(tester);
      expect(scroll.pixels, offset);
      expect(scroll.maxScrollExtent, extent);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(scroll.pixels, offset);
    },
  );

  for (var size = 4; size <= 10; size++) {
    testWidgets(
      'hint preview cancels, dismisses and confirms once at size $size',
      (tester) async {
        final container = await _open(tester, size: size);
        final before = container.read(puzzleGameProvider).game!;
        final expected = before.useSmartHint().session;
        await tester.ensureVisible(find.text('Hint'));
        final open = tester
            .widget<GameplayControls>(find.byType(GameplayControls))
            .onHint!;
        for (var tap = 0; tap < 12; tap++) {
          open();
        }
        await _settle(tester);
        expect(find.byType(NovaBottomSheet), findsOneWidget);
        expect(find.text('A little nudge'), findsOneWidget);
        expect(_session(container), same(before.session));
        await _tap(tester, find.text('Cancel'));
        expect(_session(container), same(before.session));
        await _tap(tester, find.text('Hint'));
        await tester.tapAt(const Offset(4, 40));
        await _settle(tester);
        expect(find.byType(NovaBottomSheet), findsNothing);
        expect(_session(container), same(before.session));
        await _tap(tester, find.text('Hint'));
        await tester.binding.handlePopRoute();
        await _settle(tester);
        expect(_session(container), same(before.session));
        await _tap(tester, find.text('Hint'));
        final apply = tester.widget<NovaPrimaryButton>(
          find.widgetWithText(NovaPrimaryButton, 'Apply hint'),
        );
        // Exercise repeated callbacks before the modal's exit animation finishes.
        for (var tap = 0; tap < 12; tap++) {
          apply.onPressed!();
        }
        await _settle(tester);
        expect(_session(container).toJson(), expected.toJson());
        expect(_session(container).hintsRemaining, 2);
        expect(find.byType(NovaBottomSheet), findsNothing);
        expect(find.text('Level 1'), findsOneWidget);
      },
    );
  }

  testWidgets('stale hint preview cannot apply to a changed session', (
    tester,
  ) async {
    final container = await _open(tester);
    await _tap(tester, find.text('Hint'));
    container.read(puzzleGameProvider.notifier).reset();
    final reset = _session(container);
    await _tap(tester, find.text('Apply hint'));
    expect(_session(container), same(reset));
    expect(reset.hintsRemaining, 3);
  });

  testWidgets('confirmed hint retains the Nova fallback and completion flow', (
    tester,
  ) async {
    final container = await _open(tester, size: 4);
    final controller = container.read(puzzleGameProvider.notifier);
    final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
    final last = (row: 2, column: puzzle.columnsByRow[2]);
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        final cell = (row: row, column: column);
        if (cell == last || cell == _session(container).startingNova) continue;
        controller.play(
          cell,
          mode: puzzle.isNova(cell)
              ? PuzzleInputMode.placeNova
              : PuzzleInputMode.markX,
        );
      }
    }
    await _settle(tester);
    final before = container.read(puzzleGameProvider).game!;
    await _tap(tester, find.text('Hint'));
    expect(_session(container), same(before.session));
    expect(find.textContaining('Place Nova:'), findsOneWidget);
    await _tap(tester, find.text('Apply hint'));
    expect(
      _session(container).toJson(),
      before.useSmartHint().session.toJson(),
    );
    expect(find.text('Beautifully done.'), findsOneWidget);
  });

  testWidgets(
    'normal motion loops board Novas and shakes the incorrect square',
    (tester) async {
      final container = await _open(tester, reduced: false);
      final board = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      final correct = (row: 0, column: board.columnsByRow.first);
      final wrong = (row: 1, column: correct.column);
      await placeNova(tester, _cell(correct));
      await tester.pump();
      expect(find.byType(GameplayNovaImage), findsNWidgets(2));
      await _settle(tester);

      final initial = tester.getTopLeft(_cell(wrong)).dx;
      await placeNova(tester, _cell(wrong));
      await tester.pump();
      expect(find.byType(GameplayNovaImage), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 24));
      expect(
        (tester.getTopLeft(_cell(wrong)).dx - initial).abs(),
        greaterThan(1),
      );
      await _settle(tester);
      expect(tester.getTopLeft(_cell(wrong)).dx, closeTo(initial, 0.01));
    },
  );
}

Finder _cell(CellPosition cell) => find.byKey(ValueKey(cell));
PuzzleSession _session(ProviderContainer container) =>
    container.read(puzzleSessionProvider)!;

Future<void> _useHint(WidgetTester tester) async {
  await _tap(tester, find.text('Hint'));
  if (find.text('Apply hint').evaluate().isNotEmpty) {
    await _tap(tester, find.text('Apply hint'));
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  if (tester.widget(target) is NovaGridCell) {
    await placeNova(tester, target);
  } else {
    await tester.tap(target);
  }
  await _settle(tester);
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  int size = 4,
  int level = 1,
  bool reduced = true,
  RecordingAudio? audio,
  RecordingHaptics? haptics,
  ProgressJournal? progress,
}) async {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
  final container = ProviderContainer(
    overrides: [
      if (progress != null) progressJournalProvider.overrideWithValue(progress),
      audioServiceProvider.overrideWithValue(audio ?? RecordingAudio()),
      hapticServiceProvider.overrideWithValue(haptics ?? RecordingHaptics()),
      settingsStoreProvider.overrideWithValue(_Settings(reduced)),
      puzzleWorkProvider.overrideWithValue(_TestWork(size)),
    ],
  );
  addTearDown(container.dispose);
  if (level != 1) {
    await container.read(puzzleGameProvider.notifier).startLevel(level);
  }
  container
      .read(appRouterProvider)
      .goNamed(AppRoute.gameplay.name, queryParameters: {'level': '$level'});
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NovaApp()),
  );
  await _settle(tester);
  return container;
}

final class _SlowProgressStorage implements ProgressStorage {
  final _storage = MemoryProgressStorage();
  Completer<void>? gate;

  @override
  Future<String?> read(String name) => _storage.read(name);

  @override
  Future<void> replace(String name, String content) async {
    await gate?.future;
    await _storage.replace(name, content);
  }

  @override
  Future<Set<String>> names() => _storage.names();
}

final class _Settings implements SettingsStore {
  const _Settings(this.reduced);

  final bool reduced;

  @override
  Future<AppSettings> read() async => AppSettings();

  @override
  Future<void> write(AppSettings settings) async {}
}

final class _TestWork implements PuzzleWork {
  const _TestWork(this.size);

  final int size;

  @override
  Future<GeneratedPuzzle> level(int number) async =>
      PuzzleGenerator.generate(size: size, seed: number);

  @override
  Future<GeneratedPuzzle> daily(int day) async => PuzzleCatalog.dailyByKey(day);

  @override
  Future<PuzzleGame> preview(PuzzleGame game) async => game.previewHint();

  @override
  Future<PuzzleGame> restore(Map<String, Object?> snapshot) async =>
      PuzzleGame.restore(snapshot);
}

Future<void> _undo(WidgetTester tester, ProviderContainer container) async {
  container.read(puzzleGameProvider.notifier).undo();
  await _settle(tester);
}

Future<void> _reset(WidgetTester tester) async {
  await _tap(tester, find.text('Reset'));
  await _tap(
    tester,
    find.descendant(of: find.byType(NovaDialog), matching: find.text('Reset')),
  );
}

// Continuous portrait particles intentionally never settle. Let the existing
// finite transitions finish without disabling the production animation.
Future<void> _settle(WidgetTester tester) async {
  final backdrops = find.byType(NovaParticleBackdrop);
  if (backdrops.evaluate().any(
    (element) => !MediaQuery.disableAnimationsOf(element),
  )) {
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}
