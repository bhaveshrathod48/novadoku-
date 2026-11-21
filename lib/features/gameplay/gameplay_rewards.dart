import '../../game_engine/models/puzzle.dart';
import '../../game_engine/validator/puzzle_validator.dart';

enum GameplayPraise {
  nice,
  great,
  awesome,
  wonderful,
  excellent,
  incredible,
  amazing,
  perfect,
  brilliant,
  clear,
  wellDone,
  almost,
  flawless,
  perfectClear,
}

typedef GameplayNotice = ({
  GameplayPraise title,
  GameplayPraise? subtitle,
  int strength,
  int event,
});

/// Ephemeral presentation only. Never reads the solution or writes progress.
class GameplayRewards {
  String? _puzzle;
  int combo = 0, _deductions = 0, _sequence = 0;
  final _earned = <CellPosition>{};
  final _deduced = <CellPosition>{};
  final _units = <String>{};
  bool _almost = false;

  void reset() {
    _puzzle = null;
    combo = _deductions = 0;
    _earned.clear();
    _deduced.clear();
    _units.clear();
    _almost = false;
  }

  void bind(PuzzleSession session) {
    if (_puzzle == session.puzzle.id) return;
    reset();
    _puzzle = session.puzzle.id;
    // Existing/restored discoveries are never newly earned.
    _earned.addAll(
      session.marks.entries
          .where((e) => e.value == CellMark.nova)
          .map((e) => e.key),
    );
    _deduced.addAll(session.marks.keys);
    milestones(session);
  }

  GameplayNotice _notice(
    GameplayPraise title,
    PuzzleSession session, {
    GameplayPraise? subtitle,
  }) {
    final early = (session.level ?? 11) <= 10;
    final strength = early
        ? (1 + combo ~/ 2).clamp(1, 4)
        : (1 + combo ~/ 3).clamp(1, 3);
    return (
      title: title,
      subtitle: subtitle,
      strength: strength,
      event: ++_sequence,
    );
  }

  GameplayNotice? discovery(
    PuzzleSession before,
    PuzzleSession after,
    CellPosition cell, {
    required bool player,
    required bool mistake,
  }) {
    bind(before);
    if (mistake) {
      combo = _deductions = 0;
      return null;
    }
    if (after.marks[cell] != CellMark.nova ||
        before.marks[cell] == CellMark.nova ||
        cell == after.startingNova) {
      return null;
    }
    final fresh = _earned.add(cell);
    if (!fresh) return null;
    if (player) combo++;
    final praise = GameplayPraise.values[(combo - 1).clamp(0, 6)];
    if (after.status == PuzzleStatus.completed &&
        after.attemptsRemaining == PuzzleSession.startingAttempts) {
      final unassisted =
          after.hintsRemaining == PuzzleSession.startingHints &&
          after.novaUsesRemaining == PuzzleSession.startingNovaUses;
      return _notice(
        unassisted ? GameplayPraise.perfectClear : GameplayPraise.flawless,
        after,
        subtitle: unassisted ? GameplayPraise.flawless : null,
      );
    }
    final almost = !_almost && after.puzzle.size - after.novasPlaced == 1;
    _almost |= almost;
    if (!player) return almost ? _notice(GameplayPraise.almost, after) : null;
    return _notice(
      praise,
      after,
      subtitle: almost ? GameplayPraise.almost : null,
    );
  }

  GameplayNotice? deduction(
    PuzzleSession before,
    PuzzleSession after,
    CellPosition cell,
  ) {
    bind(before);
    if (before.marks[cell] != null ||
        after.marks[cell] != CellMark.cross ||
        after.rejectedCells.contains(cell) ||
        _deduced.contains(cell)) {
      return null;
    }
    final visible = before.marks.entries
        .where((e) => e.value == CellMark.nova)
        .map((e) => e.key);
    // Praise only a consequence of public constraints, never hidden correctness.
    if (PuzzleValidator.conflict(before.puzzle, cell, visible) == null) {
      _deductions = 0;
      return null;
    }
    _deduced.add(cell);
    _deductions++;
    final threshold = (after.level ?? 11) <= 10 ? 5 : 9;
    if (_deductions % threshold != 0) return null;
    return _notice(
      GameplayPraise.values[7 + ((_deductions ~/ threshold - 1) % 4)],
      after,
    );
  }

  Set<CellPosition> milestones(PuzzleSession session) {
    final puzzle = session.puzzle;
    final result = <CellPosition>{};
    final groups = <String, List<CellPosition>>{};
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        final cell = (row: row, column: column);
        for (final key in ['r$row', 'c$column', 'g${puzzle.regionAt(cell)}']) {
          (groups[key] ??= []).add(cell);
        }
      }
    }
    for (final group in groups.entries) {
      if (_units.contains(group.key)) continue;
      if (group.value.every(session.marks.containsKey) &&
          group.value.where((c) => session.marks[c] == CellMark.nova).length ==
              1) {
        _units.add(group.key);
        result.addAll(group.value);
      }
    }
    return result;
  }
}
