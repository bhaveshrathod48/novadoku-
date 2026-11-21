import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game_engine/generator/puzzle_catalog.dart';
import 'progress_providers.dart';
import '../../game_engine/generator/puzzle_generator.dart';
import '../../game_engine/hints/hint_engine.dart';
import '../../game_engine/models/puzzle.dart';
import '../../game_engine/models/puzzle_game.dart';

abstract interface class PuzzleWork {
  Future<GeneratedPuzzle> level(int number);
  Future<GeneratedPuzzle> daily(int day);
  Future<PuzzleGame> restore(Map<String, Object?> snapshot);
  Future<PuzzleGame> preview(PuzzleGame game);
}

final class BackgroundPuzzleWork implements PuzzleWork {
  int? _chapter;
  Future<List<GeneratedPuzzle>>? _pack;

  @override
  Future<GeneratedPuzzle> level(int number) async {
    final chapter = PuzzleCatalog.chapterOf(number);
    if (_chapter != chapter) {
      _chapter = chapter;
      _pack = compute(
        PuzzleCatalog.chapter,
        chapter,
        debugLabel: 'novadoku chapter',
      );
    }
    final pending = _pack!;
    try {
      return (await pending)[(number - 1) % PuzzleCatalog.levelsPerChapter];
    } catch (_) {
      if (identical(_pack, pending)) {
        _chapter = null;
        _pack = null;
      }
      rethrow;
    }
  }

  @override
  Future<GeneratedPuzzle> daily(int day) =>
      compute(PuzzleCatalog.dailyByKey, day, debugLabel: 'novadoku daily');

  @override
  Future<PuzzleGame> restore(Map<String, Object?> snapshot) =>
      compute(PuzzleGame.restore, snapshot, debugLabel: 'novadoku restore');

  @override
  Future<PuzzleGame> preview(PuzzleGame game) =>
      compute(_previewHint, game, debugLabel: 'novadoku hint');

  static PuzzleGame _previewHint(PuzzleGame game) => game.previewHint();
}

final puzzleWorkProvider = Provider<PuzzleWork>(
  (ref) => BackgroundPuzzleWork(),
);

typedef PuzzleControllerState = ({
  PuzzleGame? game,
  AsyncValue<void> load,
  int campaignLevel,
  int unlockedThrough,
  Set<int> completedLevels,
  PuzzleGame? campaign,
  PuzzleGame? daily,
});

final puzzleGameProvider =
    NotifierProvider<PuzzleController, PuzzleControllerState>(
      PuzzleController.new,
    );

/// A null session represents the absence of a loaded puzzle.
final puzzleSessionProvider = Provider<PuzzleSession?>(
  (ref) => ref.watch(puzzleGameProvider.select((state) => state.game?.session)),
);

/// The campaign cursor starts from the saved session.
/// Daily sessions leave it where it was.
final campaignLevelProvider = Provider<int>(
  (ref) => ref.watch(puzzleGameProvider.select((state) => state.campaignLevel)),
);

/// Keyed by UTC day. Consumers can load the current day or an explicit date.
final dailyPuzzleProvider = FutureProvider.autoDispose
    .family<GeneratedPuzzle, int>(
      (ref, day) => ref.watch(puzzleWorkProvider).daily(day),
    );

final class PuzzleController extends Notifier<PuzzleControllerState> {
  int _loadRequest = 0;
  int _hintRequest = 0;
  DateTime? _dailyCompletion;
  int? _replayLevel;

  @override
  PuzzleControllerState build() {
    _loadRequest++;
    _hintRequest++;
    _replayLevel = null;
    final initial = ref.read(campaignRestoreProvider);
    final saved = initial.value;
    final game = saved?.game;
    return (
      game: game,
      load: initial.isLoading
          ? const AsyncLoading()
          : initial.whenData<void>((_) {}),
      campaignLevel: game?.session.unlockedLevel ?? game?.session.level ?? 1,
      unlockedThrough: saved?.unlockedThrough ?? 1,
      completedLevels: saved?.completed ?? const {},
      campaign: game,
      daily: null,
    );
  }

  Future<void> startLevel(int number) async {
    final initial = ref.read(campaignRestoreProvider);
    if (initial.hasError) {
      _setLoad(AsyncError(initial.error!, initial.stackTrace!));
      return;
    }
    await _load(
      (work) async =>
          PuzzleGame.start((await work.level(number)).puzzle, level: number),
    );
  }

  Future<void> startNextLevel() async {
    final next = state.game?.session.unlockedLevel;
    if (next != null && !state.load.isLoading) {
      if (_replayLevel != null) {
        await openCampaignLevel(next);
      } else {
        await startLevel(next);
      }
    }
  }

  /// Home may replay completed levels without replacing the campaign save.
  Future<void> openCampaignLevel(int level) async {
    if (level < 1 ||
        level > state.unlockedThrough ||
        (level != state.unlockedThrough &&
            !state.completedLevels.contains(level))) {
      throw RangeError.value(level, 'level', 'Level is locked');
    }
    if (!state.completedLevels.contains(level)) {
      await resumeCampaign(level);
      return;
    }
    await _load((work) async {
      final saved = await ref
          .read(progressJournalProvider)
          .read('replay-$level', work.restore);
      if (saved != null && saved.session.level != level) {
        throw const FormatException('Replay level does not match its save.');
      }
      if (saved != null && saved.session.status != PuzzleStatus.completed) {
        return saved;
      }
      return PuzzleGame.start((await work.level(level)).puzzle, level: level);
    }, replayLevel: level);
  }

  Future<void> resumeCampaign(int level) async {
    final saved = state.campaign;
    if (saved?.session.level == level) {
      _activate(saved!);
    } else {
      await startLevel(level);
    }
  }

  Future<void> startDaily(DateTime instant) =>
      resumeDaily(PuzzleCatalog.dayKey(instant));

  Future<void> resumeDaily(int day) async {
    final saved = state.daily;
    if (saved?.session.dailyDay == day) {
      _activate(saved!);
    } else {
      await _load(
        (work) async =>
            PuzzleGame.start((await work.daily(day)).puzzle, dailyDay: day),
        savedDaily: (work) => ref
            .read(progressJournalProvider)
            .read(
              DailyProgress.key(day),
              (json) => DailyProgress.decode(json, day, work.restore),
            ),
      );
    }
  }

  void _activate(PuzzleGame game) {
    ++_loadRequest;
    ++_hintRequest;
    _replayLevel = null;
    final preview = game.pendingHint;
    _commit(preview == null ? game : game.cancelHint(preview));
  }

  Future<void> restore(Map<String, Object?> snapshot) =>
      _load((work) => work.restore(snapshot));

  Future<void> _load(
    Future<PuzzleGame> Function(PuzzleWork work) run, {
    Future<DailyProgress?> Function(PuzzleWork)? savedDaily,
    int? replayLevel,
  }) async {
    final request = ++_loadRequest;
    _hintRequest++;
    _setLoad(const AsyncLoading());
    final work = ref.read(puzzleWorkProvider);
    final result = await AsyncValue.guard(() async {
      final saved = savedDaily == null ? null : await savedDaily(work);
      return (game: saved?.game ?? await run(work), saved: saved);
    });
    if (!ref.mounted || request != _loadRequest) return;
    switch (result) {
      case AsyncData(:final value):
        _replayLevel = replayLevel;
        _commit(value.game, restoredDaily: value.saved);
      case AsyncError(:final error, :final stackTrace):
        _setLoad(AsyncError(error, stackTrace));
      default:
        throw StateError('Unexpected outcome from puzzle worker.');
    }
  }

  MoveIssue? play(CellPosition cell, {PuzzleInputMode? mode}) {
    final game = state.game;
    if (state.load.isLoading || game == null) return null;
    final result = (mode == null ? game : game.selectMode(mode)).play(cell);
    _update(result.game);
    return result.issue;
  }

  /// Replace only the immediate note belonging to this double tap. A stale
  /// gesture can never roll back a hint, reset, navigation, or another edit.
  MoveIssue? playNovaAfterTap(
    CellPosition cell, {
    required PuzzleGame beforeTap,
    required PuzzleGame afterTap,
  }) {
    if (state.load.isLoading || state.game == null) return null;
    final base = identical(state.game, afterTap) ? beforeTap : state.game!;
    final result = base.selectMode(PuzzleInputMode.placeNova).play(cell);
    _update(result.game);
    return result.issue;
  }

  void selectMode(PuzzleInputMode mode) =>
      _change((game) => game.selectMode(mode));
  void revealNova() => _change((game) => game.revealNova());
  void useSmartHint() => _change((game) => game.useSmartHint());
  void undo() => _change((game) => game.undo());
  void reset() => _change((game) => game.reset());
  void retry() => _change((game) => game.retry());
  void applyHint(PuzzleHint hint) => _change((game) => game.applyHint(hint));
  void cancelHint(PuzzleHint hint) {
    if (!ref.mounted) return;
    final game = state.game;
    if (game != null && identical(game.pendingHint, hint)) {
      _hintRequest++;
      _update(game.cancelHint(hint));
    }
  }

  Future<PuzzleHint?> previewHint() async {
    final game = state.game;
    if (state.load.isLoading ||
        game == null ||
        game.session.status != PuzzleStatus.playing ||
        game.session.hintsRemaining == 0) {
      return null;
    }
    if (game.pendingHint != null) return game.pendingHint;
    final request = ++_hintRequest;
    final work = ref.read(puzzleWorkProvider);
    final result = await AsyncValue.guard(() => work.preview(game));
    if (!ref.mounted ||
        request != _hintRequest ||
        !identical(state.game, game)) {
      return null;
    }
    final updated = result.requireValue;
    _update(updated);
    return updated.pendingHint;
  }

  void _change(PuzzleGame Function(PuzzleGame game) edit) {
    final game = state.game;
    if (!state.load.isLoading && game != null) _update(edit(game));
  }

  void _update(PuzzleGame game) {
    if (identical(state.game, game)) return;
    _commit(game, load: state.load);
  }

  void _setLoad(AsyncValue<void> load) => state = (
    game: state.game,
    load: load,
    campaignLevel: state.campaignLevel,
    unlockedThrough: state.unlockedThrough,
    completedLevels: state.completedLevels,
    campaign: state.campaign,
    daily: state.daily,
  );

  void _commit(
    PuzzleGame game, {
    AsyncValue<void> load = const AsyncData(null),
    DailyProgress? restoredDaily,
  }) {
    final session = game.session;
    final level = session.level;
    final day = session.dailyDay;
    if (_replayLevel != null) {
      if (!identical(state.game?.session, session)) {
        _stage('replay-$_replayLevel', session.toJson());
      }
      state = (
        game: game,
        load: load,
        campaignLevel: state.campaignLevel,
        unlockedThrough: state.unlockedThrough,
        completedLevels: state.completedLevels,
        campaign: state.campaign,
        daily: state.daily,
      );
      return;
    }
    var unlocked = state.unlockedThrough;
    var completed = state.completedLevels;
    if (level != null) {
      unlocked = math.max(unlocked, session.unlockedLevel ?? level);
      if (session.status == PuzzleStatus.completed &&
          !completed.contains(level)) {
        completed = Set.unmodifiable({...completed, level});
      }
      if (!identical(state.campaign?.session, session)) {
        _stage(
          CampaignProgress.key,
          CampaignProgress(
            game: game,
            completed: completed,
            unlockedThrough: unlocked,
          ).toJson(),
        );
      }
    } else if (day != null) {
      if (restoredDaily != null) {
        _dailyCompletion = restoredDaily.completedAt;
      } else if (!identical(state.daily?.session, session)) {
        final previousDay = state.daily?.session.dailyDay;
        _dailyCompletion = session.status == PuzzleStatus.completed
            ? (previousDay == day ? _dailyCompletion : null) ??
                  DateTime.now().toUtc()
            : null;
        _stage(
          DailyProgress.key(day),
          DailyProgress(game, _dailyCompletion).toJson(),
        );
      }
    }
    state = (
      game: game,
      load: load,
      campaignLevel: session.unlockedLevel ?? level ?? state.campaignLevel,
      unlockedThrough: unlocked,
      completedLevels: completed,
      campaign: level == null ? state.campaign : game,
      daily: day == null ? state.daily : game,
    );
  }

  Future<void> saveCurrentProgress() {
    final session = state.game?.session;
    final journal = ref.read(progressJournalProvider);
    if (_replayLevel != null) return journal.flushKey('replay-$_replayLevel');
    if (session?.dailyDay case final day?) {
      return journal.flushKey(DailyProgress.key(day));
    }
    if (session?.level != null) return journal.flushKey(CampaignProgress.key);
    return Future.value();
  }

  void _stage(String key, Map<String, Object?> payload) {
    final journal = ref.read(progressJournalProvider);
    journal.stage(key, payload);
    unawaited(flushProgress(journal));
  }
}
