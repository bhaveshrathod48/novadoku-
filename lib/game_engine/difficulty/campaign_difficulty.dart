import 'dart:math' as math;

import '../models/puzzle.dart';
import 'difficulty_rating.dart';

/// Versioned campaign policy. Stored boards and Daily generation do not depend
/// on this schedule. A bigger board is introduced at a gentler reasoning target.
final class CampaignDifficulty {
  const CampaignDifficulty._(
    this.chapter,
    this.size,
    this.targetScore,
    this.minimumScore,
    this.maximumScore,
    this.maximumRegionTurns,
  );

  static const version = 2;
  final int chapter;
  final int size;
  final int targetScore;
  final int minimumScore;
  final int maximumScore;
  final int maximumRegionTurns;

  factory CampaignDifficulty.forChapter(int chapter) {
    if (chapter < 0) throw RangeError.value(chapter, 'chapter');
    if (chapter < 2) {
      return CampaignDifficulty._(
        chapter,
        4,
        chapter * 3,
        0,
        chapter == 0 ? 3 : 5,
        12,
      );
    }
    if (chapter < 5) {
      return CampaignDifficulty._(chapter, 5, 2 + (chapter - 2) * 2, 0, 8, 18);
    }
    if (chapter == 5) return CampaignDifficulty._(chapter, 6, 6, 0, 8, 24);
    if (chapter < 10) {
      final target = 20 + (chapter - 6) * 2;
      return CampaignDifficulty._(chapter, 6, target, 18, target + 4, 28);
    }
    if (chapter < 16) {
      final target = 24 + (chapter - 10) * 2;
      return CampaignDifficulty._(
        chapter,
        7,
        target,
        target - 6,
        target + 4,
        36,
      );
    }
    if (chapter < 24) {
      final target = 28 + (chapter - 16) * 2;
      return CampaignDifficulty._(
        chapter,
        8,
        target,
        target - 6,
        target + 4,
        48,
      );
    }
    if (chapter < 36) {
      final target = 36 + (chapter - 24) * 2;
      return CampaignDifficulty._(
        chapter,
        9,
        target,
        target - 6,
        target + 4,
        60,
      );
    }
    final target = chapter < 48
        ? 50 + (chapter - 36) * 2
        : math.min(82, 74 + (chapter - 48) ~/ 4);
    return CampaignDifficulty._(
      chapter,
      10,
      target,
      chapter >= 48 ? math.max(70, target - 6) : target - 6,
      math.min(90, target + 4),
      76,
    );
  }

  /// Separate neighboring chapters' canonical layouts without replaying or
  /// caching an ever-growing campaign history. Small introductory grids use
  /// distinct buckets throughout their entire size stage.
  bool acceptsLayout(String layout) {
    final buckets = size <= 5 ? size - 2 : 2;
    var bucket = 0;
    for (final code in layout.codeUnits) {
      bucket = (bucket * 31 + code) % buckets;
    }
    return bucket == chapter % buckets;
  }

  bool accepts(DifficultyRating rating) =>
      rating.score >= minimumScore &&
      rating.score <= maximumScore &&
      rating.contradictions == 0 &&
      rating.searchProofs == 0;

  /// Extra boundary turns beyond four per region. Rectangles/singletons have
  /// zero excess; winding outlines have more. Connectivity is checked elsewhere.
  static int regionTurns(PuzzleDefinition puzzle) {
    final size = puzzle.size;
    int at(int row, int column) =>
        row < 0 || row >= size || column < 0 || column >= size
        ? -1
        : puzzle.regionIds[row * size + column];
    var corners = 0;
    for (var row = 0; row <= size; row++) {
      for (var column = 0; column <= size; column++) {
        final a = at(row - 1, column - 1);
        final b = at(row - 1, column);
        final c = at(row, column - 1);
        final d = at(row, column);
        for (final region in {a, b, c, d}) {
          if (region == -1) continue;
          final count = [a, b, c, d].where((v) => v == region).length;
          if (count == 1 || count == 3) corners++;
          if (count == 2 &&
              ((a == region && d == region) || (b == region && c == region))) {
            corners += 2;
          }
        }
      }
    }
    return corners - 4 * size;
  }
}
