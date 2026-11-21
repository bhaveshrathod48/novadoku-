import '../models/puzzle.dart';
import '../solver/constraints.dart';
import '../solver/deductions.dart';
import '../solver/puzzle_solver.dart';
import '../validator/puzzle_validator.dart';

enum HintAction { placeNova, markX }

enum HintRule {
  row,
  column,
  region,
  touching,
  onlyCandidate,
  lockedCandidates,
  contradiction,
}

final class PuzzleHint {
  const PuzzleHint({
    required this.target,
    required this.action,
    required this.rule,
    required this.explanation,
    this.unitKind,
    this.unitNumber,
    this.searchProof = false,
  });

  final CellPosition target;
  final HintAction action;
  final HintRule rule;
  final String explanation;
  final String? unitKind;
  final int? unitNumber;
  final bool searchProof;
}

abstract final class HintEngine {
  static PuzzleHint? suggest(
    VerifiedPuzzle puzzle,
    Map<CellPosition, CellMark> marks,
  ) {
    final board = BoardConstraints(puzzle.definition);
    final placed = marks.entries
        .where((entry) => entry.value == CellMark.nova)
        .map((entry) => entry.key)
        .toList();
    final candidates = Candidates(board);
    for (final cell in placed) {
      if (!puzzle.isNova(cell)) {
        throw ArgumentError.value(cell, 'marks', 'Invalid Nova');
      }
      candidates.place(board.indexOf(cell));
    }
    if (candidates.complete) return null;

    // First offer a short deduction grounded in a Nova the player can see.
    for (var index = 0; index < board.size * board.size; index++) {
      final target = board.cellAt(index);
      if (marks.containsKey(target) || candidates.contains(index)) continue;
      final conflict = PuzzleValidator.conflict(
        puzzle.definition,
        target,
        placed,
      )!;
      final (rule, reason) = switch (conflict) {
        PlacementConflict.row => (
          HintRule.row,
          'Row ${target.row + 1} already has a Nova.',
        ),
        PlacementConflict.column => (
          HintRule.column,
          'Column ${target.column + 1} already has a Nova.',
        ),
        PlacementConflict.region => (
          HintRule.region,
          'Region ${puzzle.definition.regionAt(target)} already has a Nova.',
        ),
        PlacementConflict.touching => (
          HintRule.touching,
          'A Nova here would touch a placed Nova.',
        ),
      };
      return PuzzleHint(
        target: target,
        action: HintAction.markX,
        rule: rule,
        unitNumber: puzzle.definition.regionAt(target),
        explanation: '$reason Mark ${_cell(target)} with an X.',
      );
    }

    // A player's X marks are notes. Prove an elimination before using it.
    while (true) {
      final deduction = Deductions.next(candidates);
      if (deduction == null) return null;
      final target = board.cellAt(deduction.index);
      final unit = deduction.unit;
      final unitName = unit == null ? null : '${unit.kind.name} ${unit.number}';
      switch (deduction.technique) {
        case DeductionTechnique.single:
          return PuzzleHint(
            target: target,
            action: HintAction.placeNova,
            rule: HintRule.onlyCandidate,
            unitKind: unit?.kind.name,
            unitNumber: unit?.number,
            explanation:
                '${_cell(target, capitalize: true)} is the only possible Nova in $unitName. Place a Nova there.',
          );
        case DeductionTechnique.locked:
        case DeductionTechnique.contradiction:
        case DeductionTechnique.searchProof:
          candidates.remove(deduction.index);
          if (marks[target] == CellMark.cross) continue;
          final (rule, reason) = switch (deduction.technique) {
            DeductionTechnique.locked => (
              HintRule.lockedCandidates,
              'A Nova at ${_cell(target)} would rule out every possible Nova in $unitName.',
            ),
            DeductionTechnique.contradiction => (
              HintRule.contradiction,
              'A Nova at ${_cell(target)} would force moves that leave $unitName without a Nova.',
            ),
            _ => (
              HintRule.contradiction,
              'Assuming a Nova at ${_cell(target)} leaves no way to satisfy all rows, columns, regions, and the no-touch rule.',
            ),
          };
          return PuzzleHint(
            target: target,
            action: HintAction.markX,
            rule: rule,
            unitKind: unit?.kind.name,
            unitNumber: unit?.number,
            searchProof: deduction.technique == DeductionTechnique.searchProof,
            explanation: '$reason Mark ${_cell(target)} with an X.',
          );
      }
    }
  }

  static String _cell(CellPosition target, {bool capitalize = false}) =>
      '${capitalize ? 'Row' : 'row'} ${target.row + 1}, column ${target.column + 1}';
}
