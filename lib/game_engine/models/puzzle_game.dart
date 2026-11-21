import '../hints/hint_engine.dart';
import '../solver/puzzle_solver.dart';
import '../validator/puzzle_validator.dart';
import 'puzzle.dart';

enum MoveIssue {
  outsideBoard,
  sameRow,
  sameColumn,
  sameRegion,
  touching,
  wrongCell,
}

typedef MoveResult = ({PuzzleGame game, MoveIssue? issue});

/// Immutable game transitions. Invalid Nova placements spend one attempt and
/// add a protected red X. Preview and undo never return a spent budget.
final class PuzzleGame {
  const PuzzleGame._(this.verifiedPuzzle, this.session, [this.pendingHint]);

  factory PuzzleGame.start(VerifiedPuzzle puzzle, {int? level, int? dailyDay}) {
    if (level != null && level < 1) throw RangeError.value(level, 'level');
    if (level != null && dailyDay != null) {
      throw ArgumentError('Choose either a campaign level or a daily day.');
    }
    final startingNova = (
      row: puzzle.definition.size - 1,
      column: puzzle.columnsByRow.last,
    );
    return PuzzleGame._(
      puzzle,
      PuzzleSession(
        puzzle: puzzle.definition,
        attemptsRemaining: PuzzleSession.startingAttempts,
        hintsRemaining: PuzzleSession.startingHints,
        mode: PuzzleInputMode.placeNova,
        marks: {startingNova: CellMark.nova},
        startingNova: startingNova,
        level: level,
        dailyDay: dailyDay,
      ),
    );
  }

  final VerifiedPuzzle verifiedPuzzle;
  final PuzzleSession session;
  final PuzzleHint? pendingHint;

  bool get _playing => session.status == PuzzleStatus.playing;

  PuzzleGame selectMode(PuzzleInputMode mode) {
    if (!_playing || session.mode == mode) return this;
    return _with(mode: mode);
  }

  MoveResult play(CellPosition target) {
    if (!_playing) return (game: this, issue: null);
    if (!session.puzzle.contains(target)) {
      return (game: this, issue: MoveIssue.outsideBoard);
    }
    final before = session.marks[target];
    if (before == CellMark.nova || session.rejectedCells.contains(target)) {
      return (game: this, issue: null);
    }
    if (session.mode == PuzzleInputMode.markX) {
      return (
        game: _edit(target, before == CellMark.cross ? null : CellMark.cross),
        issue: null,
      );
    }

    final placed = session.marks.entries
        .where((entry) => entry.value == CellMark.nova)
        .map((entry) => entry.key);
    final conflict = PuzzleValidator.conflict(session.puzzle, target, placed);
    final issue = switch (conflict) {
      PlacementConflict.row => MoveIssue.sameRow,
      PlacementConflict.column => MoveIssue.sameColumn,
      PlacementConflict.region => MoveIssue.sameRegion,
      PlacementConflict.touching => MoveIssue.touching,
      null => verifiedPuzzle.isNova(target) ? null : MoveIssue.wrongCell,
    };
    if (issue != null) {
      return (
        game: _with(
          attempts: session.attemptsRemaining - 1,
          marks: {...session.marks, target: CellMark.cross},
          rejectedCells: {...session.rejectedCells, target},
        ),
        issue: issue,
      );
    }
    return (game: _edit(target, CellMark.nova), issue: null);
  }

  PuzzleGame undo() {
    if (!_playing || session.history.isEmpty) return this;
    final edit = session.history.last;
    final marks = Map.of(session.marks);
    if (!session.rejectedCells.contains(edit.cell)) {
      _setMark(marks, edit.cell, edit.before);
    }
    return _with(
      marks: marks,
      history: session.history.take(session.history.length - 1),
    );
  }

  /// Starts the same board with fresh budgets after a reset or failed attempt.
  PuzzleGame reset() => session.status == PuzzleStatus.completed
      ? this
      : PuzzleGame._(
          verifiedPuzzle,
          PuzzleSession(
            puzzle: session.puzzle,
            level: session.level,
            dailyDay: session.dailyDay,
            attemptsRemaining: PuzzleSession.startingAttempts,
            hintsRemaining: PuzzleSession.startingHints,
            mode: PuzzleInputMode.placeNova,
            startingNova: session.startingNova,
            marks: {?session.startingNova: CellMark.nova},
          ),
        );

  PuzzleGame retry() => session.status == PuzzleStatus.failed ? reset() : this;

  PuzzleGame previewHint() {
    if (!_playing || session.hintsRemaining == 0 || pendingHint != null) {
      return this;
    }
    final hint = HintEngine.suggest(verifiedPuzzle, session.marks);
    return hint == null ? this : PuzzleGame._(verifiedPuzzle, session, hint);
  }

  PuzzleGame cancelHint(PuzzleHint hint) => identical(pendingHint, hint)
      ? PuzzleGame._(verifiedPuzzle, session)
      : this;

  PuzzleGame applyHint(PuzzleHint hint) {
    if (!_playing || !identical(pendingHint, hint)) return this;
    final mark = hint.action == HintAction.placeNova
        ? CellMark.nova
        : CellMark.cross;
    return _edit(hint.target, mark, hints: session.hintsRemaining - 1);
  }

  /// Reveal from the verified solution; ordinary notes can never hide a Nova.
  PuzzleGame revealNova({bool usingHint = false}) {
    if (!_playing ||
        (usingHint ? session.hintsRemaining : session.novaUsesRemaining) == 0) {
      return this;
    }
    for (final (row, column) in verifiedPuzzle.columnsByRow.indexed) {
      final target = (row: row, column: column);
      if (session.marks[target] == CellMark.nova) continue;
      return _edit(
        target,
        CellMark.nova,
        hints: usingHint ? session.hintsRemaining - 1 : null,
        novaUses: usingHint ? null : session.novaUsesRemaining - 1,
      );
    }
    return this;
  }

  /// Up to four new, provably excluded notes per use. Prefer cells close to a
  /// visible Nova. Never use a player's X as evidence for a deduction.
  PuzzleGame useSmartHint() {
    if (!_playing || session.hintsRemaining == 0) return this;
    final placed = session.marks.entries
        .where((e) => e.value == CellMark.nova)
        .map((e) => e.key)
        .toList();
    final excluded = <CellPosition>[];
    for (var row = 0; row < session.puzzle.size; row++) {
      for (var column = 0; column < session.puzzle.size; column++) {
        final cell = (row: row, column: column);
        if (!session.marks.containsKey(cell) &&
            PuzzleValidator.conflict(session.puzzle, cell, placed) != null) {
          excluded.add(cell);
        }
      }
    }
    int distance(CellPosition cell) {
      var nearest = session.puzzle.size;
      for (final nova in placed) {
        final dx = (cell.column - nova.column).abs();
        final dy = (cell.row - nova.row).abs();
        final d = dx > dy ? dx : dy;
        if (d < nearest) nearest = d;
      }
      return nearest;
    }

    excluded.sort((a, b) {
      final d = distance(a).compareTo(distance(b));
      if (d != 0) return d;
      final r = a.row.compareTo(b.row);
      return r != 0 ? r : a.column.compareTo(b.column);
    });
    if (excluded.isEmpty) return revealNova(usingHint: true);
    final targets = excluded.take(4);
    return _with(
      hints: session.hintsRemaining - 1,
      marks: {
        ...session.marks,
        for (final cell in targets) cell: CellMark.cross,
      },
      history: [
        ...session.history,
        for (final cell in targets)
          (cell: cell, before: null, after: CellMark.cross),
      ],
    );
  }

  PuzzleGame _edit(
    CellPosition cell,
    CellMark? mark, {
    int? hints,
    int? novaUses,
  }) {
    final before = session.marks[cell];
    if (before == mark) return this;
    final marks = Map.of(session.marks);
    _setMark(marks, cell, mark);
    return _with(
      marks: marks,
      hints: hints,
      novaUses: novaUses,
      history: [...session.history, (cell: cell, before: before, after: mark)],
    );
  }

  PuzzleGame _with({
    PuzzleInputMode? mode,
    int? attempts,
    int? hints,
    int? novaUses,
    Map<CellPosition, CellMark>? marks,
    Iterable<CellChange>? history,
    Set<CellPosition>? rejectedCells,
  }) => PuzzleGame._(
    verifiedPuzzle,
    PuzzleSession(
      puzzle: session.puzzle,
      level: session.level,
      dailyDay: session.dailyDay,
      mode: mode ?? session.mode,
      attemptsRemaining: attempts ?? session.attemptsRemaining,
      hintsRemaining: hints ?? session.hintsRemaining,
      novaUsesRemaining: novaUses ?? session.novaUsesRemaining,
      marks: marks ?? session.marks,
      history: history ?? session.history,
      startingNova: session.startingNova,
      rejectedCells: rejectedCells ?? session.rejectedCells,
    ),
  );

  static void _setMark(
    Map<CellPosition, CellMark> marks,
    CellPosition cell,
    CellMark? mark,
  ) {
    if (mark == null) {
      marks.remove(cell);
    } else {
      marks[cell] = mark;
    }
  }

  /// Reads a versioned snapshot from storage and revalidates the board and moves.
  factory PuzzleGame.restore(Map<String, Object?> json) {
    if (json['version'] != 1 && json['version'] != 2 && json['version'] != 3) {
      throw const FormatException('Unsupported game snapshot version.');
    }
    final board = json['puzzle'];
    final level = json['level'];
    final dailyDay = json['dailyDay'];
    final attempts = json['attempts'];
    final hints = json['hints'];
    final novaUses = json['version'] == 3
        ? json['novaUses']
        : PuzzleSession.startingNovaUses;
    final mode = json['mode'];
    final edits = json['history'];
    if (board is! Map<String, Object?> ||
        (level != null && (level is! int || level < 1)) ||
        (dailyDay != null && (dailyDay is! int || level != null)) ||
        !_validBudget(attempts, PuzzleSession.startingAttempts) ||
        !_validBudget(hints, PuzzleSession.startingHints) ||
        !_validBudget(novaUses, PuzzleSession.startingNovaUses) ||
        edits is! List ||
        !PuzzleInputMode.values.any((option) => option.name == mode)) {
      throw const FormatException('Malformed game snapshot.');
    }
    final definition = PuzzleDefinition.fromJson(board);
    final verified = PuzzleSolver.verify(definition);
    CellPosition? startingNova;
    final rejectedCells = <CellPosition>{};
    CellPosition readCell(Object? value) {
      if (value is! List ||
          value.length != 2 ||
          value[0] is! int ||
          value[1] is! int) {
        throw const FormatException('Malformed protected cell.');
      }
      final cell = (row: value[0] as int, column: value[1] as int);
      if (!definition.contains(cell)) {
        throw const FormatException('Protected cell outside board.');
      }
      return cell;
    }

    if (json['version'] == 2 || json['version'] == 3) {
      if (!json.containsKey('startingNova')) {
        throw const FormatException('Missing starting Nova field.');
      }
      if (json['startingNova'] != null) {
        startingNova = readCell(json['startingNova']);
        if (!verified.isNova(startingNova)) {
          throw const FormatException('Invalid starting Nova.');
        }
      }
      final rejected = json['rejected'];
      if (rejected is! List) {
        throw const FormatException('Missing rejected cells.');
      }
      for (final value in rejected) {
        final cell = readCell(value);
        if (verified.isNova(cell) || !rejectedCells.add(cell)) {
          throw const FormatException('Invalid rejected cell.');
        }
      }
      if (rejectedCells.length >
          PuzzleSession.startingAttempts - (attempts as int)) {
        throw const FormatException('Rejected cells exceed spent attempts.');
      }
    }
    final marks = <CellPosition, CellMark>{?startingNova: CellMark.nova};
    final history = <CellChange>[];
    var novas = startingNova == null ? 0 : 1;
    for (final edit in edits) {
      if (edit is! List ||
          edit.length != 3 ||
          edit[0] is! int ||
          edit[1] is! int ||
          novas == definition.size) {
        throw const FormatException('Malformed move history.');
      }
      final cell = (row: edit[0] as int, column: edit[1] as int);
      final before = marks[cell];
      final after = switch (edit[2]) {
        null => null,
        'cross' => CellMark.cross,
        'nova' => CellMark.nova,
        _ => throw const FormatException('Unknown cell mark.'),
      };
      if (!definition.contains(cell) ||
          before == after ||
          before == CellMark.nova ||
          (after == CellMark.nova && !verified.isNova(cell))) {
        throw const FormatException('Invalid move in snapshot.');
      }
      if (after == CellMark.nova) novas++;
      _setMark(marks, cell, after);
      history.add((cell: cell, before: before, after: after));
    }
    for (final cell in rejectedCells) {
      marks[cell] = CellMark.cross;
    }
    if (attempts == 0 && novas == definition.size) {
      throw const FormatException('A failed puzzle cannot also be completed.');
    }
    return PuzzleGame._(
      verified,
      PuzzleSession(
        puzzle: definition,
        level: level as int?,
        dailyDay: dailyDay as int?,
        attemptsRemaining: attempts as int,
        hintsRemaining: hints as int,
        novaUsesRemaining: novaUses as int,
        mode: PuzzleInputMode.values.firstWhere(
          (option) => option.name == mode,
        ),
        marks: marks,
        history: history,
        startingNova: startingNova,
        rejectedCells: rejectedCells,
      ),
    );
  }

  static bool _validBudget(Object? value, int maximum) =>
      value is int && value >= 0 && value <= maximum;
}
