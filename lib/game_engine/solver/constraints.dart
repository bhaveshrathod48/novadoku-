import '../models/puzzle.dart';

enum UnitKind { row, column, region }

typedef PuzzleUnit = ({UnitKind kind, int number, List<int> cells});

/// Compiles the three families of exact-one units and each cell's peer masks.
final class BoardConstraints {
  BoardConstraints(this.puzzle) {
    final groups = <int, List<int>>{};
    for (var index = 0; index < size * size; index++) {
      (groups[puzzle.regionIds[index]] ??= []).add(index);
    }
    units = [
      for (var row = 0; row < size; row++)
        (
          kind: UnitKind.row,
          number: row + 1,
          cells: List.generate(size, (column) => row * size + column),
        ),
      for (var column = 0; column < size; column++)
        (
          kind: UnitKind.column,
          number: column + 1,
          cells: List.generate(size, (row) => row * size + column),
        ),
      for (final entry in groups.entries)
        (kind: UnitKind.region, number: entry.key, cells: entry.value),
    ];
    peers = List.generate(size * size, (source) {
      final row = source ~/ size;
      final column = source % size;
      final bit = 1 << column;
      final masks = List.filled(size, bit);
      masks[row] = ((1 << size) - 1) ^ bit;
      for (final regionPeer in groups[puzzle.regionIds[source]]!) {
        if (regionPeer != source) {
          masks[regionPeer ~/ size] |= 1 << (regionPeer % size);
        }
      }
      final near = (bit | (bit << 1) | (bit >> 1)) & ((1 << size) - 1);
      if (row > 0) masks[row - 1] |= near;
      if (row + 1 < size) masks[row + 1] |= near;
      return masks;
    });
  }

  final PuzzleDefinition puzzle;
  late final List<PuzzleUnit> units;
  late final List<List<int>> peers;

  int get size => puzzle.size;

  int indexOf(CellPosition cell) => cell.row * size + cell.column;
  CellPosition cellAt(int index) => (row: index ~/ size, column: index % size);

  bool conflict(int a, int b) => peers[a][b ~/ size] & (1 << (b % size)) != 0;
}

/// Mutable scratch state for one search branch or one deduction pass.
final class Candidates {
  Candidates(this.board)
    : rows = List.filled(board.size, (1 << board.size) - 1);
  Candidates.copy(Candidates source)
    : board = source.board,
      rows = List.of(source.rows),
      fixedRows = source.fixedRows;

  final BoardConstraints board;
  final List<int> rows;
  int fixedRows = 0;

  bool contains(int index) =>
      (rows[index ~/ board.size] & (1 << (index % board.size))) != 0;
  bool isFixed(int index) =>
      (fixedRows & (1 << (index ~/ board.size))) != 0 && contains(index);
  bool get complete => fixedRows == (1 << board.size) - 1;

  void remove(int index) =>
      rows[index ~/ board.size] &= ~(1 << (index % board.size));

  bool place(int index) {
    if (!contains(index)) return false;
    final row = index ~/ board.size;
    rows[row] = 1 << (index % board.size);
    fixedRows |= 1 << row;
    final masks = board.peers[index];
    for (var other = 0; other < rows.length; other++) {
      rows[other] &= ~masks[other];
      if (rows[other] == 0) return false;
    }
    return true;
  }

  /// -1 means no candidate, -2 means two or more, otherwise the lone candidate.
  int singleIn(PuzzleUnit unit) {
    var found = -1;
    for (final index in unit.cells) {
      if (!contains(index)) continue;
      if (found >= 0) return -2;
      found = index;
    }
    return found;
  }

  /// Applies forced moves to a fixed point and identifies an exhausted unit.
  PuzzleUnit? propagate() {
    var changed = true;
    while (changed) {
      changed = false;
      for (final unit in board.units) {
        final single = singleIn(unit);
        if (single == -1) return unit;
        if (single >= 0 && !isFixed(single)) {
          if (!place(single)) {
            return board.units.firstWhere((item) => singleIn(item) == -1);
          }
          changed = true;
        }
      }
    }
    return null;
  }

  Iterable<int> get undecided sync* {
    for (var row = 0; row < rows.length; row++) {
      if ((fixedRows & (1 << row)) != 0) continue;
      var available = rows[row];
      while (available != 0) {
        final bit = available & -available;
        yield row * board.size + bit.bitLength - 1;
        available ^= bit;
      }
    }
  }
}
