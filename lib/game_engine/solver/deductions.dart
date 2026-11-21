import 'constraints.dart';
import 'puzzle_solver.dart';

enum DeductionTechnique { single, locked, contradiction, searchProof }

typedef Deduction = ({
  int index,
  DeductionTechnique technique,
  PuzzleUnit? unit,
});

abstract final class Deductions {
  static Deduction? next(
    Candidates candidates, {
    DeductionTechnique maximumTechnique = DeductionTechnique.searchProof,
  }) {
    final board = candidates.board;
    for (final unit in board.units) {
      final index = candidates.singleIn(unit);
      if (index >= 0 && !candidates.isFixed(index)) {
        return (index: index, technique: DeductionTechnique.single, unit: unit);
      }
    }

    if (maximumTechnique == DeductionTechnique.single) return null;

    for (final unit in board.units) {
      final common = List.filled(board.size, (1 << board.size) - 1);
      var support = 0;
      for (final index in unit.cells) {
        if (!candidates.contains(index)) continue;
        support++;
        final peers = board.peers[index];
        for (var row = 0; row < board.size; row++) {
          common[row] &= peers[row];
        }
      }
      if (support < 2) continue;
      for (var row = 0; row < board.size; row++) {
        final clashes = common[row] & candidates.rows[row];
        if (clashes != 0) {
          final first = clashes & -clashes;
          return (
            index: row * board.size + first.bitLength - 1,
            technique: DeductionTechnique.locked,
            unit: unit,
          );
        }
      }
    }

    if (maximumTechnique == DeductionTechnique.locked) return null;

    final possible = <(int, Candidates)>[];
    for (final index in candidates.undecided) {
      final branch = Candidates.copy(candidates);
      branch.place(index);
      final exhausted = branch.propagate();
      if (exhausted != null) {
        return (
          index: index,
          technique: DeductionTechnique.contradiction,
          unit: exhausted,
        );
      }
      possible.add((index, branch));
    }
    if (maximumTechnique == DeductionTechnique.contradiction) return null;

    // A verified board has one continuation. A branch with zero solutions
    // supplies a proof without using the stored solution to pick a move.
    for (final (index, branch) in possible) {
      if (PuzzleSolver.search(branch, limit: 1).count == 0) {
        return (
          index: index,
          technique: DeductionTechnique.searchProof,
          unit: null,
        );
      }
    }
    return null;
  }
}
