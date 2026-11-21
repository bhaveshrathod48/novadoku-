import '../models/puzzle.dart';
import '../validator/puzzle_validator.dart';
import 'constraints.dart';

typedef SolutionSearch = ({int count, List<int>? firstColumns, int nodes});

final class VerifiedPuzzle {
  VerifiedPuzzle._(this.definition, Iterable<int> columns)
    : columnsByRow = List.unmodifiable(columns);

  final PuzzleDefinition definition;
  final List<int> columnsByRow;

  bool isNova(CellPosition cell) =>
      definition.contains(cell) && columnsByRow[cell.row] == cell.column;
}

abstract final class PuzzleSolver {
  static SolutionSearch solve(PuzzleDefinition puzzle) {
    PuzzleValidator.requireValid(puzzle);
    return search(Candidates(BoardConstraints(puzzle)));
  }

  static VerifiedPuzzle verify(PuzzleDefinition puzzle) {
    final result = solve(puzzle);
    if (result.count != 1) {
      throw FormatException(
        result.count == 0
            ? 'Puzzle has no solution.'
            : 'Puzzle has multiple solutions.',
      );
    }
    return VerifiedPuzzle._(puzzle, result.firstColumns!);
  }

  /// Count up to [limit], branching on the tightest remaining exact-one unit.
  static SolutionSearch search(Candidates seed, {int limit = 2}) {
    assert(limit > 0);
    var count = 0;
    var nodes = 0;
    List<int>? firstColumns;

    void visit(Candidates candidates) {
      nodes++;
      if (candidates.propagate() != null) return;
      if (candidates.complete) {
        count++;
        firstColumns ??= List.unmodifiable(
          candidates.rows.map((bits) => bits.bitLength - 1),
        );
        return;
      }
      List<int>? best;
      for (final unit in candidates.board.units) {
        final cells = unit.cells.where(candidates.contains).toList();
        if (cells.length <= 1 ||
            (best != null && cells.length >= best.length)) {
          continue;
        }
        best = cells;
        if (best.length == 2) break;
      }
      for (final index in best!) {
        final branch = Candidates.copy(candidates);
        if (branch.place(index)) visit(branch);
        if (count == limit) return;
      }
    }

    visit(Candidates.copy(seed));
    return (count: count, firstColumns: firstColumns, nodes: nodes);
  }
}
