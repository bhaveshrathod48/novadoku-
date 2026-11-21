typedef CellPosition = ({int row, int column});

/// Region IDs are non-negative and stored in row-major order.
final class PuzzleDefinition {
  PuzzleDefinition({
    required this.id,
    required this.size,
    required Iterable<int> regionIds,
  }) : regionIds = List.unmodifiable(regionIds);

  final String id;
  final int size;
  final List<int> regionIds;

  bool contains(CellPosition cell) =>
      cell.row >= 0 &&
      cell.row < size &&
      cell.column >= 0 &&
      cell.column < size;

  int regionAt(CellPosition cell) {
    if (!contains(cell)) throw RangeError('Cell is outside the puzzle: $cell');
    return regionIds[cell.row * size + cell.column];
  }

  Map<String, Object> toJson() => {
    'id': id,
    'size': size,
    'regions': regionIds,
  };

  factory PuzzleDefinition.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final size = json['size'];
    final regions = json['regions'];
    if (id is! String ||
        size is! int ||
        regions is! List ||
        regions.any((region) => region is! int)) {
      throw const FormatException('Malformed puzzle definition.');
    }
    return PuzzleDefinition(id: id, size: size, regionIds: regions.cast<int>());
  }
}

enum PuzzleInputMode { placeNova, markX }

enum CellMark { nova, cross }

enum PuzzleStatus { playing, completed, failed }

typedef CellChange = ({CellPosition cell, CellMark? before, CellMark? after});

/// Empty cells are absent from [marks]. History contains reversible board edits.
final class PuzzleSession {
  PuzzleSession({
    required this.puzzle,
    required this.attemptsRemaining,
    required this.mode,
    required this.hintsRemaining,
    required Map<CellPosition, CellMark> marks,
    Iterable<CellChange> history = const [],
    this.level,
    this.dailyDay,
    this.startingNova,
    this.novaUsesRemaining = startingNovaUses,
    Iterable<CellPosition> rejectedCells = const [],
  }) : marks = Map.unmodifiable(marks),
       history = List.unmodifiable(history),
       rejectedCells = Set.unmodifiable(rejectedCells);

  static const startingAttempts = 3;
  static const startingHints = 3;
  static const startingNovaUses = 4;

  final PuzzleDefinition puzzle;
  final int? level;

  /// UTC days since the epoch for a daily challenge.
  final int? dailyDay;
  final int attemptsRemaining;
  final int hintsRemaining;
  final int novaUsesRemaining;
  final PuzzleInputMode mode;
  final Map<CellPosition, CellMark> marks;
  final List<CellChange> history;
  final CellPosition? startingNova;
  final Set<CellPosition> rejectedCells;

  int get novasPlaced =>
      marks.values.where((mark) => mark == CellMark.nova).length;

  PuzzleStatus get status {
    if (attemptsRemaining == 0) return PuzzleStatus.failed;
    return novasPlaced == puzzle.size
        ? PuzzleStatus.completed
        : PuzzleStatus.playing;
  }

  int? get unlockedLevel =>
      status == PuzzleStatus.completed && level != null ? level! + 1 : null;

  /// Reconstruct marks from the fixed Nova, reversible history and protected Xs.
  Map<String, Object?> toJson() => {
    'version': 3,
    'novaUses': novaUsesRemaining,
    'startingNova': startingNova == null
        ? null
        : [startingNova!.row, startingNova!.column],
    'rejected': [
      for (final cell in rejectedCells) [cell.row, cell.column],
    ],
    'puzzle': puzzle.toJson(),
    'level': level,
    'dailyDay': dailyDay,
    'attempts': attemptsRemaining,
    'hints': hintsRemaining,
    'mode': mode.name,
    'history': [
      for (final edit in history)
        [edit.cell.row, edit.cell.column, edit.after?.name],
    ],
  };
}
