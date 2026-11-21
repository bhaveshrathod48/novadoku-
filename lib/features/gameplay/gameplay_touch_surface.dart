import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/app_tokens.dart';
import '../../game_engine/models/puzzle.dart';

/// Board-wide gesture ownership keeps a swipe from becoming a page scroll.
/// Cell semantics and keyboard actions remain on the individual cells.
class GameplayTouchSurface extends StatefulWidget {
  const GameplayTouchSurface({
    super.key,
    required this.size,
    required this.child,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSwipe,
    required this.swipeModeAt,
    this.epoch = 0,
  });
  final int size;
  final Widget child;
  final ValueChanged<CellPosition>? onTap;
  final ValueChanged<CellPosition>? onDoubleTap;
  final void Function(CellPosition, bool)? onSwipe;
  final bool? Function(CellPosition) swipeModeAt;
  final int epoch;

  @override
  State<GameplayTouchSurface> createState() => _GameplayTouchSurfaceState();
}

class _GameplayTouchSurfaceState extends State<GameplayTouchSurface> {
  final _surface = GlobalKey();
  final _visited = <CellPosition>{};
  Timer? _doubleWindow;
  CellPosition? _lastTap;
  Offset? _lastTapPosition;
  Offset? _down;
  Offset? _previous;
  bool? _swipeAdd;
  int _pointers = 0;
  bool _multiTouch = false;

  CellPosition? _cellAt(Offset point) {
    final box = _surface.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.size.contains(point)) return null;
    final side =
        (box.size.width - AppTokens.gridGap * (widget.size - 1)) / widget.size;
    final step = side + AppTokens.gridGap;
    final row = (point.dy / step).floor();
    final column = (point.dx / step).floor();
    if (row >= widget.size ||
        column >= widget.size ||
        point.dx % step > side ||
        point.dy % step > side) {
      return null;
    }
    return (row: row, column: column);
  }

  void _clearDouble() {
    _doubleWindow?.cancel();
    _lastTap = null;
    _lastTapPosition = null;
  }

  void _tap(TapUpDetails details) {
    if (_multiTouch) return;
    final cell = _cellAt(details.localPosition);
    if (cell == null) {
      _clearDouble();
      return;
    }
    final previous = _lastTapPosition;
    if (_lastTap == cell &&
        previous != null &&
        (previous - details.localPosition).distance <= kDoubleTapSlop) {
      _clearDouble();
      widget.onDoubleTap?.call(cell);
    } else {
      _clearDouble();
      widget.onTap?.call(cell);
      _lastTap = cell;
      _lastTapPosition = details.localPosition;
      _doubleWindow = Timer(kDoubleTapTimeout, _clearDouble);
    }
  }

  void _visitCell(CellPosition cell) {
    final add = _swipeAdd;
    if (add != null && _visited.add(cell)) widget.onSwipe?.call(cell, add);
  }

  // Intersect the stroke with a cell's central area. Merely grazing a rounded
  // corner or crossing a gap must not mark an unintended neighboring cell.
  double? _entry(Offset a, Offset b, Rect rect) {
    var enter = 0.0;
    var exit = 1.0;
    for (var axis = 0; axis < 2; axis++) {
      final start = axis == 0 ? a.dx : a.dy;
      final end = axis == 0 ? b.dx : b.dy;
      final lower = axis == 0 ? rect.left : rect.top;
      final upper = axis == 0 ? rect.right : rect.bottom;
      final delta = end - start;
      if (delta.abs() < .000001) {
        if (start <= lower || start >= upper) return null;
        continue;
      }
      var first = (lower - start) / delta;
      var last = (upper - start) / delta;
      if (first > last) {
        final swap = first;
        first = last;
        last = swap;
      }
      if (first > enter) enter = first;
      if (last < exit) exit = last;
      if (enter >= exit) return null;
    }
    return enter;
  }

  void _swipe(Offset point) {
    if (_multiTouch || _swipeAdd == null) return;
    final box = _surface.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final previous = _previous ?? point;
    if (previous == point) return;
    final side =
        (box.size.width - AppTokens.gridGap * (widget.size - 1)) / widget.size;
    final step = side + AppTokens.gridGap;
    final hits = <({CellPosition cell, double time})>[];
    // A segment cannot hit a cell outside these bounds. Keep the exact
    // existing inner-cell intersections and stroke order inside this range.
    final firstRow = (math.min(previous.dy, point.dy) / step).floor().clamp(
      0,
      widget.size - 1,
    );
    final lastRow = (math.max(previous.dy, point.dy) / step).floor().clamp(
      0,
      widget.size - 1,
    );
    final firstColumn = (math.min(previous.dx, point.dx) / step).floor().clamp(
      0,
      widget.size - 1,
    );
    final lastColumn = (math.max(previous.dx, point.dx) / step).floor().clamp(
      0,
      widget.size - 1,
    );
    for (var row = firstRow; row <= lastRow; row++) {
      for (var column = firstColumn; column <= lastColumn; column++) {
        final cell = (row: row, column: column);
        if (_visited.contains(cell)) continue;
        final rect = Rect.fromLTWH(
          column * step,
          row * step,
          side,
          side,
        ).deflate(side * .18);
        final time = _entry(previous, point, rect);
        if (time != null) hits.add((cell: cell, time: time));
      }
    }
    hits.sort((a, b) => a.time.compareTo(b.time));
    for (final hit in hits) {
      _visitCell(hit.cell);
    }
    _previous = point;
  }

  @override
  void didUpdateWidget(covariant GameplayTouchSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null || widget.epoch != oldWidget.epoch) {
      _clearDouble();
      _visited.clear();
      _previous = null;
      if (_pointers > 0) _multiTouch = true;
    }
  }

  @override
  void dispose() {
    _doubleWindow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (_pointers++ == 0) _multiTouch = false;
      if (_pointers > 1) {
        _multiTouch = true;
        _clearDouble();
      }
    },
    onPointerUp: (_) => _pointers--,
    onPointerCancel: (_) => _pointers--,
    child: GestureDetector(
      key: _surface,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapUp: widget.onTap == null ? null : _tap,
      onPanDown: widget.onSwipe == null
          ? null
          : (details) {
              _down = details.localPosition;
            },
      onPanStart: widget.onSwipe == null
          ? null
          : (details) {
              _clearDouble();
              _visited.clear();
              _previous = _down ?? details.localPosition;
              final initial = _cellAt(_previous!);
              _swipeAdd = initial == null ? null : widget.swipeModeAt(initial);
              if (!_multiTouch && initial != null) _visitCell(initial);
              _swipe(details.localPosition);
            },
      onPanUpdate: widget.onSwipe == null
          ? null
          : (details) => _swipe(details.localPosition),
      onPanEnd: (_) {
        _visited.clear();
        _previous = null;
      },
      onPanCancel: () {
        _visited.clear();
        _previous = null;
      },
      child: widget.child,
    ),
  );
}
