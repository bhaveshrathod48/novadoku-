import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/progress_storage_io.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/models/puzzle.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restart restores independent exact campaign and dated Daily sessions',
    () async {
      final directory = await _temporaryDirectory();
      final worker = BackgroundPuzzleWork();
      Future<ProviderContainer> launch() async {
        final journal = ProgressJournal(
          FileProgressStorage(() async => directory),
        );
        final saved = await journal.read(
          CampaignProgress.key,
          (json) => CampaignProgress.decode(json, worker.restore),
        );
        return ProviderContainer(
          overrides: [
            progressJournalProvider.overrideWithValue(journal),
            campaignRestoreProvider.overrideWithValue(AsyncData(saved)),
            puzzleWorkProvider.overrideWithValue(worker),
          ],
        );
      }

      final first = await launch();
      final controller = first.read(puzzleGameProvider.notifier);
      await controller.startLevel(1);
      _solve(first);
      await controller.saveCurrentProgress();

      final afterCompletion = await launch();
      expect(afterCompletion.read(campaignLevelProvider), 2);
      expect(afterCompletion.read(puzzleGameProvider).completedLevels, {1});
      expect(
        afterCompletion.read(puzzleSessionProvider)!.status,
        PuzzleStatus.completed,
      );
      afterCompletion.dispose();

      await controller.startNextLevel();
      expect(first.read(campaignLevelProvider), 2);
      final level = first.read(puzzleGameProvider).game!;
      final target = (row: 0, column: level.verifiedPuzzle.columnsByRow.first);
      controller.play(target);
      final wrong = (row: 1, column: target.column);
      expect(controller.play(wrong), MoveIssue.sameColumn);
      final preview = (await controller.previewHint())!;
      controller.applyHint(preview);
      controller.selectMode(PuzzleInputMode.markX);
      final note = (
        row: 1,
        column: (target.column + 2) % level.session.puzzle.size,
      );
      if (note != preview.target) controller.play(note);
      final campaign = first.read(puzzleSessionProvider)!;
      expect(campaign.attemptsRemaining, 2);
      expect(campaign.hintsRemaining, 2);
      expect(
        campaign.marks.values.toSet(),
        containsAll([CellMark.nova, CellMark.cross]),
      );

      final late = DateTime.utc(2026, 11, 18, 23, 59);
      final rollover = late.add(const Duration(minutes: 1));
      final day = PuzzleCatalog.dayKey(late);
      final nextDay = PuzzleCatalog.dayKey(rollover);
      await controller.startDaily(late);
      _solve(first);
      final completedDay = first.read(puzzleSessionProvider)!.toJson();
      await controller.startDaily(rollover);
      expect(first.read(puzzleSessionProvider)!.dailyDay, day + 1);
      expect(first.read(puzzleSessionProvider)!.status, PuzzleStatus.playing);
      controller.selectMode(PuzzleInputMode.markX);
      controller.play((row: 0, column: 0));
      final daily = first.read(puzzleSessionProvider)!.toJson();
      await first.read(progressJournalProvider).flush();
      first.dispose();

      final restarted = await launch();
      addTearDown(restarted.dispose);
      expect(restarted.read(campaignLevelProvider), 2);
      expect(restarted.read(puzzleGameProvider).completedLevels, {1});
      expect(restarted.read(puzzleGameProvider).unlockedThrough, 2);
      expect(
        restarted.read(puzzleSessionProvider)!.toJson(),
        campaign.toJson(),
      );
      final resumed = restarted.read(puzzleGameProvider.notifier);
      resumed.undo();
      expect(
        restarted.read(puzzleSessionProvider)!.history,
        hasLength(campaign.history.length - 1),
      );
      expect(restarted.read(puzzleSessionProvider)!.attemptsRemaining, 2);
      expect(restarted.read(puzzleSessionProvider)!.hintsRemaining, 2);
      await resumed.resumeDaily(nextDay);
      expect(restarted.read(puzzleSessionProvider)!.toJson(), daily);
      await resumed.resumeDaily(day);
      expect(restarted.read(puzzleSessionProvider)!.toJson(), completedDay);
      final journal = restarted.read(progressJournalProvider);
      final dates = await DailyProgress.completions(journal);
      expect(dates.keys, [day]);
      expect(dates[day]!.isUtc, isTrue);
      await resumed.resumeCampaign(2);
      expect(
        restarted.read(puzzleSessionProvider)!.history.length,
        campaign.history.length - 1,
      );
      await journal.flush();
    },
  );

  test(
    'flushed copies recover from truncated writes and corruption independently',
    () async {
      final directory = await _temporaryDirectory();
      final storage = FileProgressStorage(() async => directory);
      final journal = ProgressJournal(storage);
      await journal.write('campaign', {'version': 1, 'counter': 1});
      await journal.write('campaign', {'version': 1, 'counter': 2});
      await journal.write('daily-17', {'version': 1, 'counter': 9});
      await File('${directory.path}/campaign.1.tmp')
          .writeAsString('interrupted');
      final reader = ProgressJournal(storage);
      expect(await _counter(reader, 'campaign'), 2);

      await File('${directory.path}/campaign.0').writeAsBytes([0xff, 0xfe]);
      final recovered = ProgressJournal(storage);
      expect(await _counter(recovered, 'campaign'), 1);
      expect(await _counter(recovered, 'daily-17'), 9);
      await recovered.write('campaign', {'version': 1, 'counter': 3});
      expect(await _counter(ProgressJournal(storage), 'campaign'), 3);

      await File('${directory.path}/campaign.0').writeAsString('{broken');
      await File('${directory.path}/campaign.1').writeAsString('{broken');
      final reset = ProgressJournal(storage);
      expect(await _counter(reset, 'campaign'), isNull);
      expect(await _counter(reset, 'daily-17'), 9);
    },
  );

  test(
    'semantic corruption falls back and a future save is preserved',
    () async {
      final storage = MemoryProgressStorage();
      final journal = ProgressJournal(storage);
      await journal.write('campaign', {'version': 1, 'counter': 1});
      await journal.write('campaign', {'version': 1, 'counter': 'invalid'});
      expect(await _counter(ProgressJournal(storage), 'campaign'), 1);

      await journal.write('daily-42', {'version': 2, 'counter': 100});
      final reader = ProgressJournal(storage);
      await expectLater(
        _counter(reader, 'daily-42'),
        throwsA(isA<UnsupportedProgressVersion>()),
      );
      final untouched = Map.of(storage.files);
      await expectLater(
        reader.write('daily-42', {'version': 1, 'counter': 5}),
        throwsA(isA<UnsupportedProgressVersion>()),
      );
      expect(storage.files, untouched);
    },
  );

  test(
    'writes serialize, retry safely and keep unrelated records independent',
    () async {
      final storage = _BlockingStorage();
      final journal = ProgressJournal(storage);
      final gate = Completer<void>();
      storage.gate = gate;
      journal.stage('campaign', {'version': 1, 'counter': 1});
      final write = journal.flush();
      await storage.started.future;
      journal.stage('campaign', {'version': 1, 'counter': 2});
      journal.stage('daily-1', {'version': 1, 'counter': 9});
      gate.complete();
      await write;
      expect(storage.maxWriters, 1);
      expect(await _counter(ProgressJournal(storage), 'campaign'), 2);

      storage.failCampaign = true;
      journal.stage('campaign', {'version': 1, 'counter': 3});
      await journal.write('settings', {'version': 1, 'counter': 10});
      expect(await _counter(ProgressJournal(storage), 'campaign'), 2);
      expect(await _counter(ProgressJournal(storage), 'settings'), 10);
      expect(await _counter(ProgressJournal(storage), 'daily-1'), 9);
      storage.failCampaign = false;
      await journal.flushKey('campaign');
      expect(await _counter(ProgressJournal(storage), 'campaign'), 3);
    },
  );

  test(
    'all settings restore from the journal without legacy platform access',
    () async {
      final journal = ProgressJournal(MemoryProgressStorage());
      final store = LocalSettingsStore(
        journal,
        readLegacy: () async => ['music', 'haptics'],
      );
      final legacy = await store.read();
      expect(legacy.music, isTrue);
      expect(legacy.haptics, isTrue);
      expect(legacy.soundEffects, isFalse);
      const wanted = AppSettings(
        music: true,
        soundEffects: false,
        haptics: false,
        regionPatterns: true,
        language: AppLanguage.english,
      );
      await store.write(wanted);
      final restored = await LocalSettingsStore(
        ProgressJournal(journal.storage),
        readLegacy: () async => throw StateError('Legacy should not be read'),
      ).read();
      expect(restored.music, wanted.music);
      expect(restored.soundEffects, wanted.soundEffects);
      expect(restored.haptics, wanted.haptics);
      expect(restored.regionPatterns, wanted.regionPatterns);
      expect(restored.language, wanted.language);
    },
  );
}

Future<int?> _counter(ProgressJournal journal, String key) =>
    journal.read(key, (json) {
      final counter = json['counter'];
      if (counter is! int) throw const FormatException('Invalid counter');
      return counter;
    });

Future<Directory> _temporaryDirectory() async {
  final directory = await Directory.systemTemp.createTemp(
    'novadoku-progress-test-',
  );
  addTearDown(() => directory.delete(recursive: true));
  return directory;
}

void _solve(ProviderContainer container) {
  final controller = container.read(puzzleGameProvider.notifier);
  final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
  for (final (row, column) in puzzle.columnsByRow.indexed) {
    expect(controller.play((row: row, column: column)), isNull);
  }
  expect(container.read(puzzleSessionProvider)!.status, PuzzleStatus.completed);
}

final class _BlockingStorage implements ProgressStorage {
  final _memory = MemoryProgressStorage();
  Completer<void>? gate;
  final started = Completer<void>();
  int _writers = 0;
  int maxWriters = 0;
  bool failCampaign = false;

  @override
  Future<String?> read(String name) => _memory.read(name);

  @override
  Future<void> replace(String name, String content) async {
    _writers++;
    if (_writers > maxWriters) maxWriters = _writers;
    try {
      if (!started.isCompleted) started.complete();
      await gate?.future;
      if (failCampaign && name.startsWith('campaign')) {
        throw StateError('Disk full');
      }
      await _memory.replace(name, content);
    } finally {
      _writers--;
    }
  }

  @override
  Future<Set<String>> names() => _memory.names();
}
