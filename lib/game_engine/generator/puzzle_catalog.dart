import '../difficulty/campaign_difficulty.dart';
import 'puzzle_generator.dart';

/// Versioned, repeatable sources shared by UI and future storage adapters.
abstract final class PuzzleCatalog {
  static const levelsPerChapter = 4;
  static const _seedModulus = 2147483646;

  static int chapterOf(int number) {
    RangeError.checkValueInInterval(number, 1, _seedModulus, 'number');
    return (number - 1) ~/ levelsPerChapter;
  }

  static GeneratedPuzzle level(int number) =>
      chapter(chapterOf(number))[(number - 1) % levelsPerChapter];

  static List<GeneratedPuzzle> chapter(int index) {
    RangeError.checkValueInInterval(
      index,
      0,
      (_seedModulus - 1) ~/ levelsPerChapter,
      'index',
    );
    final policy = CampaignDifficulty.forChapter(index);
    final used = <String>{};
    final pack = <GeneratedPuzzle>[];

    for (var entry = 0; entry < levelsPerChapter; entry++) {
      final ordinal = index * levelsPerChapter + entry + 1;
      final seed = (ordinal * 104729 + 25117) % _seedModulus;
      final puzzle = _campaignPuzzle(policy, seed, used);
      used.add(puzzle.layout);
      pack.add(puzzle);
    }
    pack.sort((a, b) {
      final score = a.difficulty.score.compareTo(b.difficulty.score);
      return score != 0 ? score : a.layout.compareTo(b.layout);
    });
    return List.unmodifiable(pack);
  }

  static GeneratedPuzzle _campaignPuzzle(
    CampaignDifficulty policy,
    int seed,
    Set<String> used,
  ) {
    for (var retry = 0; retry < 8; retry++) {
      try {
        return PuzzleGenerator.generate(
          size: policy.size,
          seed: (seed + retry * 748721) % _seedModulus,
          campaign: policy,
          excludedLayouts: used,
        );
      } on PuzzleGenerationExhausted {
        // Keep every hard bound; a harder or speculative puzzle is no fallback.
      }
    }
    throw PuzzleGenerationExhausted(
      'Campaign candidates exhausted for seed $seed.',
    );
  }

  /// All players receive the same board for the same UTC calendar day.
  static GeneratedPuzzle daily(DateTime instant) => dailyByKey(dayKey(instant));

  static int dayKey(DateTime instant) {
    final utc = instant.toUtc();
    final midnight = DateTime.utc(utc.year, utc.month, utc.day);
    return midnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  static GeneratedPuzzle dailyByKey(int day) {
    RangeError.checkValueInInterval(day, -100000000, 100000000, 'day');
    final seed = (day * 65537 + 197333) % _seedModulus;
    return PuzzleGenerator.generate(
      size: 6 + day % 5,
      seed: -1 - seed,
      targetScore: 18 + (day % 7) * 8,
    );
  }
}
