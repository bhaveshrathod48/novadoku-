import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/progress_journal.dart';
import '../../game_engine/models/puzzle.dart';
import '../../game_engine/models/puzzle_game.dart';

final progressJournalProvider = Provider<ProgressJournal>(
  (ref) => ProgressJournal(MemoryProgressStorage()),
);

final campaignRestoreProvider = Provider<AsyncValue<CampaignProgress?>>(
  (ref) => const AsyncData(null),
);

Future<void> flushProgress(ProgressJournal journal) async {
  try {
    await journal.flush();
  } catch (error, stack) {
    developer.log(
      'Progress save could not be committed',
      name: 'novadoku.progress',
      error: error,
      stackTrace: stack,
    );
  }
}

final class CampaignProgress {
  const CampaignProgress({
    required this.game,
    required this.completed,
    required this.unlockedThrough,
  });

  static const key = 'campaign';

  final PuzzleGame game;
  final Set<int> completed;
  final int unlockedThrough;

  ProgressJson toJson() => {
    'version': 1,
    'completed': completed.toList()..sort(),
    'unlockedThrough': unlockedThrough,
    'session': game.session.toJson(),
  };

  static Future<CampaignProgress> decode(
    ProgressJson json,
    Future<PuzzleGame> Function(ProgressJson) restore,
  ) async {
    final snapshot = json['session'];
    final levels = json['completed'];
    final unlocked = json['unlockedThrough'];
    if (json['version'] != 1 ||
        snapshot is! ProgressJson ||
        levels is! List ||
        unlocked is! int ||
        unlocked < 1 ||
        levels.any(
          (level) => level is! int || level < 1 || level >= unlocked,
        )) {
      throw const FormatException('Invalid campaign progress.');
    }
    final game = await restore(snapshot);
    final level = game.session.level;
    final completed = levels.cast<int>().toSet();
    if (level == null ||
        level > unlocked ||
        (game.session.status == PuzzleStatus.completed &&
            !completed.contains(level))) {
      throw const FormatException('Campaign session and unlocks disagree.');
    }
    return CampaignProgress(
      game: game,
      completed: Set.unmodifiable(completed),
      unlockedThrough: unlocked,
    );
  }
}

final class DailyProgress {
  const DailyProgress(this.game, this.completedAt);

  final PuzzleGame game;
  final DateTime? completedAt;

  static String key(int day) => 'daily-$day';

  ProgressJson toJson() => {
    'version': 1,
    'session': game.session.toJson(),
    'completedAt': completedAt?.millisecondsSinceEpoch,
  };

  static (ProgressJson, DateTime?) _decode(ProgressJson json, int day) {
    final snapshot = json['session'];
    final time = json['completedAt'];
    if (json['version'] != 1 ||
        snapshot is! ProgressJson ||
        snapshot['dailyDay'] != day ||
        snapshot['level'] != null ||
        (time != null && (time is! int || time.abs() > 8640000000000000))) {
      throw const FormatException('Invalid Daily progress.');
    }
    return (
      snapshot,
      time == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(time as int, isUtc: true),
    );
  }

  static Future<DailyProgress> decode(
    ProgressJson json,
    int day,
    Future<PuzzleGame> Function(ProgressJson) restore,
  ) async {
    final (snapshot, time) = _decode(json, day);
    final game = await restore(snapshot);
    if ((game.session.status == PuzzleStatus.completed) != (time != null)) {
      throw const FormatException(
        'Daily session and completion date disagree.',
      );
    }
    return DailyProgress(game, time);
  }

  /// UTC challenge keys map to the actual UTC completion instant.
  static Future<Map<int, DateTime>> completions(ProgressJournal journal) async {
    final completed = <int, DateTime>{};
    for (final key in await journal.keys()) {
      if (!key.startsWith('daily-')) continue;
      final day = int.tryParse(key.substring(6));
      if (day == null) continue;
      try {
        final time = await journal.read<DateTime?>(
          key,
          (json) => _decode(json, day).$2,
        );
        if (time != null) completed[day] = time;
      } on UnsupportedProgressVersion {
        // Leave future records intact while listing readable dates.
      }
    }
    return Map.unmodifiable(completed);
  }
}
