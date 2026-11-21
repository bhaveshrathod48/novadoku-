import 'dart:math' as math;

import '../solver/constraints.dart';
import '../solver/deductions.dart';
import '../solver/puzzle_solver.dart';

enum DifficultyBand { gentle, standard, challenging, expert }

final class DifficultyRating {
  const DifficultyRating({
    required this.score,
    required this.singles,
    required this.lockedEliminations,
    required this.contradictions,
    required this.searchProofs,
  });

  final int score;
  final int singles;
  final int lockedEliminations;
  final int contradictions;
  final int searchProofs;

  DifficultyBand get band => switch (score) {
    < 12 => DifficultyBand.gentle,
    < 35 => DifficultyBand.standard,
    < 70 => DifficultyBand.challenging,
    _ => DifficultyBand.expert,
  };
}

abstract final class PuzzleDifficulty {
  static DifficultyRating rate(VerifiedPuzzle puzzle) =>
      measure(BoardConstraints(puzzle.definition));

  /// Measures the techniques needed to finish a board already checked for uniqueness.
  static DifficultyRating measure(BoardConstraints board) {
    final candidates = Candidates(board);
    return _measure(candidates) ??
        (throw StateError('Unique puzzle yielded no deduction.'));
  }

  /// Campaign difficulty is assessed from the same fixed Nova players receive.
  /// No speculative placement or backtracking proof is permitted in this pass.
  static DifficultyRating? fromStartingNova(BoardConstraints board, int index) {
    final candidates = Candidates(board);
    if (!candidates.place(index)) return null;
    return _measure(candidates, maximumTechnique: DeductionTechnique.locked);
  }

  static DifficultyRating? _measure(
    Candidates candidates, {
    DeductionTechnique maximumTechnique = DeductionTechnique.searchProof,
  }) {
    final board = candidates.board;
    final opening = <int>{};
    for (final unit in board.units) {
      final single = candidates.singleIn(unit);
      if (single >= 0) opening.add(single);
    }
    var singles = 0;
    var locked = 0;
    var contradictions = 0;
    var proofs = 0;

    while (!candidates.complete) {
      final deduction = Deductions.next(
        candidates,
        maximumTechnique: maximumTechnique,
      );
      if (deduction == null) {
        return null;
      }
      switch (deduction.technique) {
        case DeductionTechnique.single:
          singles++;
          if (!candidates.place(deduction.index)) {
            throw StateError('A deduction contradicted the puzzle.');
          }
        case DeductionTechnique.locked:
          locked++;
          candidates.remove(deduction.index);
        case DeductionTechnique.contradiction:
          contradictions++;
          candidates.remove(deduction.index);
        case DeductionTechnique.searchProof:
          proofs++;
          candidates.remove(deduction.index);
      }
    }
    final openingPressure = ((1 - opening.length / board.size) * 10).round();
    final score = switch ((proofs, contradictions, locked)) {
      (> 0, _, _) =>
        80 + math.min<int>(30, proofs * 4 + contradictions * 2 + locked ~/ 4),
      (_, > 0, _) => 50 + math.min<int>(29, contradictions * 4 + locked ~/ 2),
      (_, _, > 0) =>
        18 +
            math.min<int>(
              maximumTechnique == DeductionTechnique.locked ? 72 : 31,
              locked * 2 + openingPressure ~/ 2,
            ),
      _ => openingPressure,
    };
    return DifficultyRating(
      score: score,
      singles: singles,
      lockedEliminations: locked,
      contradictions: contradictions,
      searchProofs: proofs,
    );
  }
}
