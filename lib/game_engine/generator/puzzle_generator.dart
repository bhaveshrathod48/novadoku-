import '../difficulty/difficulty_rating.dart';
import '../difficulty/campaign_difficulty.dart';
import '../models/puzzle.dart';
import '../solver/constraints.dart';
import '../solver/puzzle_solver.dart';
import '../validator/puzzle_validator.dart';

typedef GeneratedPuzzle = ({
  VerifiedPuzzle puzzle,
  DifficultyRating difficulty,
  String layout,
});

/// A bounded candidate search failed to satisfy the requested policy.
/// Callers may retry a different deterministic seed, never relax correctness.
final class PuzzleGenerationExhausted extends StateError {
  PuzzleGenerationExhausted(super.message);
}

abstract final class PuzzleGenerator {
  static const version = 1;
  static const _samplingBudget = 32;
  static const _ratedSamplingBudget = 72;
  static const _fallbackBudget = 4;

  /// Produces the same board for the same parameters, including the exclusion set.
  static GeneratedPuzzle generate({
    required int size,
    required int seed,
    int? targetScore,
    Set<String> excludedLayouts = const {},
    CampaignDifficulty? campaign,
  }) {
    RangeError.checkValueInInterval(
      size,
      PuzzleValidator.minimumSize,
      PuzzleValidator.maximumSize,
      'size',
    );
    targetScore = campaign?.targetScore ?? targetScore;
    if (targetScore != null) {
      RangeError.checkValueInInterval(targetScore, 0, 110, 'targetScore');
    }
    final random = _SeededRandom(seed);
    if (campaign != null && campaign.size != size) {
      throw ArgumentError('Campaign policy and board size differ.');
    }
    final prefix = campaign == null
        ? 'v$version'
        : 'campaign-v${CampaignDifficulty.version}';
    final id = '$prefix-$size-$seed-${targetScore ?? 'any'}';
    PuzzleDefinition? bestPuzzle;
    DifficultyRating? bestRating;
    String? bestLayout;
    var bestDistance = 1 << 30;

    bool consider(List<int> regions) {
      if (!_hasIrregularRegion(regions, size)) return false;
      final definition = PuzzleDefinition(
        id: id,
        size: size,
        regionIds: regions,
      );
      final constraints = BoardConstraints(definition);
      if (campaign != null &&
          CampaignDifficulty.regionTurns(definition) >
              campaign.maximumRegionTurns) {
        return false;
      }
      final layout = layoutKey(definition);
      if (excludedLayouts.contains(layout)) return false;
      if (campaign != null && !campaign.acceptsLayout(layout)) return false;
      final solution = PuzzleSolver.search(Candidates(constraints));
      if (solution.count != 1) return false;
      final rating = campaign == null
          ? PuzzleDifficulty.measure(constraints)
          : PuzzleDifficulty.fromStartingNova(
              constraints,
              (size - 1) * size + solution.firstColumns!.last,
            );
      if (rating == null || (campaign != null && !campaign.accepts(rating))) {
        return false;
      }
      final distance = targetScore == null
          ? 0
          : (targetScore - rating.score).abs();
      if (distance < bestDistance) {
        bestPuzzle = definition;
        bestRating = rating;
        bestLayout = layout;
        bestDistance = distance;
      }
      return distance <= 2;
    }

    final budget = targetScore == null ? _samplingBudget : _ratedSamplingBudget;
    for (var attempt = 0; attempt < budget; attempt++) {
      final anchors = _anchors(size, random);
      if (consider(_growRegions(anchors, size, random))) break;
    }
    if (bestPuzzle == null || bestDistance > 3) {
      final fallbackBudget = campaign == null ? _fallbackBudget : 96;
      for (var attempt = 0; attempt < fallbackBudget; attempt++) {
        final preserved = switch (targetScore ?? 110) {
          < 18 => size - 2,
          _ when campaign != null => 0,
          < 50 => attempt.isEven ? size ~/ 2 : 0,
          _ => 0,
        };
        if (consider(
          _growUniqueRegions(
            _anchors(size, random),
            size,
            random,
            id,
            preserved,
          ),
        )) {
          break;
        }
        if (targetScore == null && bestPuzzle != null) break;
      }
    }
    if (bestPuzzle == null) {
      throw PuzzleGenerationExhausted(
        'Generation exhausted its budget for size $size and seed $seed.',
      );
    }
    // Construction labels follow anchor rows. Publish independent labels so
    // the region numbers cannot reveal that relationship.
    final labels = List.generate(size, (index) => index + 1);
    _SeededRandom(seed % 2147483646 + 16057).shuffle(labels);
    return (
      puzzle: PuzzleSolver.verify(
        PuzzleDefinition(
          id: '$id-$bestLayout',
          size: size,
          regionIds: bestPuzzle!.regionIds.map((region) => labels[region - 1]),
        ),
      ),
      difficulty: bestRating!,
      layout: bestLayout!,
    );
  }

  static List<int> _anchors(int size, _SeededRandom random) {
    final available = (1 << size) - 1;
    final columns = List.filled(size, 0);
    final orders = List.generate(size, (_) {
      final order = List.generate(size, (column) => column);
      random.shuffle(order);
      return order;
    });

    bool assign(int row, int unused, int previous) {
      if (row == size) return true;
      for (final column in orders[row]) {
        final bit = 1 << column;
        if ((unused & bit) == 0 || (column - previous).abs() <= 1) continue;
        columns[row] = column;
        if (assign(row + 1, unused ^ bit, column)) return true;
      }
      return false;
    }

    if (!assign(0, available, -2)) {
      throw StateError('No non-touching column permutation.');
    }
    return [for (var row = 0; row < size; row++) row * size + columns[row]];
  }

  static List<int> _growRegions(
    List<int> anchors,
    int size,
    _SeededRandom random,
  ) {
    final regions = List.filled(size * size, 0);
    final frontiers = List.generate(size, (_) => <int>{});
    final counts = List.filled(size, 1);
    for (final (region, anchor) in anchors.indexed) {
      regions[anchor] = region + 1;
    }
    for (final (region, anchor) in anchors.indexed) {
      frontiers[region].addAll(
        PuzzleValidator.orthogonalNeighbors(
          anchor,
          size,
        ).where((cell) => regions[cell] == 0),
      );
    }

    // Alternate unbiased growth with a preference for smaller regions.
    for (var remaining = size * size - size; remaining > 0; remaining--) {
      final active = [
        for (var i = 0; i < size; i++)
          if (frontiers[i].isNotEmpty) i,
      ];
      var region = active[random.nextInt(active.length)];
      if (random.nextInt(3) != 0) {
        final other = active[random.nextInt(active.length)];
        if (counts[other] < counts[region]) region = other;
      }
      final frontier = frontiers[region];
      final cell = frontier.elementAt(random.nextInt(frontier.length));
      regions[cell] = region + 1;
      counts[region]++;
      for (final set in frontiers) {
        set.remove(cell);
      }
      frontier.addAll(
        PuzzleValidator.orthogonalNeighbors(
          cell,
          size,
        ).where((neighbor) => regions[neighbor] == 0),
      );
    }
    return regions;
  }

  /// A unique partition with singleton anchors can be grown while checking each
  /// transfer. Rejected transfers leave the previous valid partition intact.
  static List<int> _growUniqueRegions(
    List<int> anchors,
    int size,
    _SeededRandom random,
    String id,
    int preserved,
  ) {
    final donor = random.nextInt(size) + 1;
    final regions = List.filled(size * size, donor);
    for (final (region, anchor) in anchors.indexed) {
      regions[anchor] = region + 1;
    }
    final fixed = anchors.toSet();
    final receivers = [
      for (var region = 1; region <= size; region++)
        if (region != donor) region,
    ];
    random.shuffle(receivers);
    final growing = receivers.skip(preserved).toSet();
    final order = List.generate(size * size, (cell) => cell);
    for (var pass = 0; pass < 3; pass++) {
      random.shuffle(order);
      var changed = false;
      for (final cell in order) {
        if (regions[cell] != donor || fixed.contains(cell)) continue;
        final adjacent = PuzzleValidator.orthogonalNeighbors(cell, size)
            .map((neighbor) => regions[neighbor])
            .where(growing.contains)
            .toSet()
            .toList();
        random.shuffle(adjacent);
        for (final region in adjacent) {
          regions[cell] = region;
          final board = PuzzleDefinition(
            id: id,
            size: size,
            regionIds: regions,
          );
          if (PuzzleValidator.inspect(board) == null &&
              PuzzleSolver.search(Candidates(BoardConstraints(board))).count ==
                  1) {
            changed = true;
            break;
          }
          regions[cell] = donor;
        }
      }
      if (!changed) break;
    }
    return regions;
  }

  static bool _hasIrregularRegion(List<int> regions, int size) {
    for (var region = 1; region <= size; region++) {
      var count = 0;
      var top = size;
      var left = size;
      var bottom = -1;
      var right = -1;
      for (var cell = 0; cell < regions.length; cell++) {
        if (regions[cell] != region) continue;
        final row = cell ~/ size;
        final column = cell % size;
        count++;
        if (row < top) top = row;
        if (row > bottom) bottom = row;
        if (column < left) left = column;
        if (column > right) right = column;
      }
      if (count != (bottom - top + 1) * (right - left + 1)) return true;
    }
    return false;
  }

  /// Canonical under region renaming, rotations, and reflections.
  static String layoutKey(PuzzleDefinition puzzle) {
    String? best;
    final size = puzzle.size;
    for (var symmetry = 0; symmetry < 8; symmetry++) {
      final names = <int, int>{};
      final key = StringBuffer('$size:');
      for (var row = 0; row < size; row++) {
        for (var column = 0; column < size; column++) {
          final r = (symmetry & 1) == 0 ? row : size - 1 - row;
          final c = (symmetry & 2) == 0 ? column : size - 1 - column;
          final cell = (symmetry & 4) == 0 ? r * size + c : c * size + r;
          final region = names.putIfAbsent(
            puzzle.regionIds[cell],
            () => names.length,
          );
          key.writeCharCode(65 + region);
        }
      }
      final value = key.toString();
      if (best == null || value.compareTo(best) < 0) best = value;
    }
    return best!;
  }
}

// Park–Miller with exact arithmetic on both the Dart VM and JavaScript.
final class _SeededRandom {
  _SeededRandom(int seed) : _state = seed % (_modulus - 1) + 1;

  static const _modulus = 2147483647;
  int _state;

  int nextInt(int bound) {
    _state = (_state * 48271) % _modulus;
    return (_state - 1) % bound;
  }

  void shuffle<T>(List<T> items) {
    for (var last = items.length - 1; last > 0; last--) {
      final swap = nextInt(last + 1);
      final item = items[last];
      items[last] = items[swap];
      items[swap] = item;
    }
  }
}
