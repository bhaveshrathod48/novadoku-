import '../models/puzzle.dart';

enum BoardIssue {
  missingId,
  size,
  cellCount,
  regionId,
  regionCount,
  disconnectedRegion,
}

enum PlacementConflict { row, column, region, touching }

abstract final class PuzzleValidator {
  static const minimumSize = 4;
  static const maximumSize = 10;

  static BoardIssue? inspect(PuzzleDefinition puzzle) {
    final size = puzzle.size;
    if (puzzle.id.trim().isEmpty) return BoardIssue.missingId;
    if (size < minimumSize || size > maximumSize) return BoardIssue.size;
    if (puzzle.regionIds.length != size * size) return BoardIssue.cellCount;
    final counts = <int, int>{};
    for (final region in puzzle.regionIds) {
      if (region < 0) return BoardIssue.regionId;
      counts.update(region, (count) => count + 1, ifAbsent: () => 1);
    }
    if (counts.length != size) return BoardIssue.regionCount;

    final visited = List.filled(size * size, false);
    final seenRegions = <int>{};
    for (var start = 0; start < visited.length; start++) {
      if (visited[start]) continue;
      final region = puzzle.regionIds[start];
      if (!seenRegions.add(region)) return BoardIssue.disconnectedRegion;
      final pending = [start];
      visited[start] = true;
      while (pending.isNotEmpty) {
        for (final neighbor in orthogonalNeighbors(
          pending.removeLast(),
          size,
        )) {
          if (!visited[neighbor] && puzzle.regionIds[neighbor] == region) {
            visited[neighbor] = true;
            pending.add(neighbor);
          }
        }
      }
    }
    return null;
  }

  static void requireValid(PuzzleDefinition puzzle) {
    final issue = inspect(puzzle);
    if (issue != null) {
      throw FormatException('Invalid puzzle board: ${issue.name}.');
    }
  }

  static PlacementConflict? conflict(
    PuzzleDefinition puzzle,
    CellPosition target,
    Iterable<CellPosition> placed,
  ) {
    if (placed.any((cell) => cell.row == target.row)) {
      return PlacementConflict.row;
    }
    if (placed.any((cell) => cell.column == target.column)) {
      return PlacementConflict.column;
    }
    final region = puzzle.regionAt(target);
    if (placed.any((cell) => puzzle.regionAt(cell) == region)) {
      return PlacementConflict.region;
    }
    if (placed.any(
      (cell) =>
          (cell.row - target.row).abs() <= 1 &&
          (cell.column - target.column).abs() <= 1,
    )) {
      return PlacementConflict.touching;
    }
    return null;
  }

  static bool isSolution(
    PuzzleDefinition puzzle,
    Iterable<CellPosition> placements,
  ) {
    if (inspect(puzzle) != null) return false;
    final seen = <CellPosition>[];
    for (final cell in placements) {
      if (!puzzle.contains(cell) || conflict(puzzle, cell, seen) != null) {
        return false;
      }
      seen.add(cell);
    }
    return seen.length == puzzle.size;
  }

  static Iterable<int> orthogonalNeighbors(int index, int size) sync* {
    if (index >= size) yield index - size;
    if (index < size * (size - 1)) yield index + size;
    if (index % size != 0) yield index - 1;
    if (index % size != size - 1) yield index + 1;
  }
}
