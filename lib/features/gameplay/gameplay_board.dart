import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../l10n/nova_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../game_engine/models/puzzle.dart';
import '../../shared/characters/nova_assets.dart';
import 'gameplay_cross.dart';
import 'gameplay_nova.dart';
import 'gameplay_motion.dart';
import 'gameplay_mistake_cell.dart';
import '../../shared/widgets/nova_grid_cell.dart';
import 'gameplay_region_progress.dart';
import 'gameplay_region_pattern.dart';
import 'gameplay_touch_surface.dart';

typedef GameplayReaction = ({
  CellPosition cell,
  NovaExpression expression,
  int event,
});
typedef GameplayShake = ({CellPosition cell, int event});

class GameplayBoard extends StatefulWidget {
  const GameplayBoard({
    super.key,
    required this.session,
    required this.onCellPressed,
    required this.onNovaPressed,
    required this.onSwipeCell,
    required this.onReactionCompleted,
    this.shake,
    this.hint,
    this.hintCellKey,
    this.hintPulse = 0,
    this.reaction,
    this.showRegionPatterns = false,
    this.gestureEpoch = 0,
    this.restartEpoch = 0,
    this.highlights = const {},
    this.milestones = const {},
  });

  final PuzzleSession session;
  final ValueChanged<CellPosition>? onCellPressed;
  final ValueChanged<CellPosition>? onNovaPressed;
  final void Function(CellPosition, bool)? onSwipeCell;
  final ValueChanged<GameplayReaction> onReactionCompleted;
  final GameplayShake? shake;
  final CellPosition? hint;
  final GlobalKey? hintCellKey;
  final int hintPulse;
  final GameplayReaction? reaction;
  final bool showRegionPatterns;
  final int gestureEpoch;
  final int restartEpoch;
  final Set<CellPosition> highlights;
  final Set<CellPosition> milestones;

  @override
  State<GameplayBoard> createState() => _GameplayBoardState();
}

/// Memoize presentation only. State and all game transitions stay in the
/// existing controller. The cache is bounded to this board's 4–10 squared cells.
class _GameplayBoardState extends State<GameplayBoard>
    with SingleTickerProviderStateMixin {
  late Map<int, NovaRegionTone> _colors;
  final _cells = <CellPosition, ({Object signature, Widget child})>{};
  late final AnimationController _entrance;
  bool _started = false;
  bool _restarting = false;

  @override
  void initState() {
    super.initState();
    _colors = gameplayRegionColors(widget.session.puzzle);
    _entrance = AnimationController(
      vsync: this,
      duration: GameplayMotion.entrance,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (!_started) {
      _entrance.forward();
    }
    _started = true;
  }

  @override
  void didUpdateWidget(covariant GameplayBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session.puzzle, widget.session.puzzle)) {
      _colors = gameplayRegionColors(widget.session.puzzle);
      _cells.clear();
    }
    if (oldWidget.restartEpoch != widget.restartEpoch) {
      _restarting = true;
      _entrance.duration = GameplayMotion.clear + GameplayMotion.entrance;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entrance.value = 1;
      } else {
        _entrance.forward(from: 0);
      }
    }
  }

  // Direct manipulation wins over decorative entrance motion. Never hide or
  // defer an edit behind an entrance/restart, or change the touch hit regions.
  void _finishEntrance() {
    if (_entrance.isAnimating) _entrance.value = 1;
  }

  @override
  void dispose() {
    _cells.clear();
    _entrance.dispose();
    super.dispose();
  }

  Widget _cell(
    BuildContext context,
    CellPosition cell,
    Map<int, NovaRegionTone> colors,
  ) {
    final highlighted = widget.hint == cell || widget.highlights.contains(cell);
    final signature = (
      mark: widget.session.marks[cell],
      rejected: widget.session.rejectedCells.contains(cell),
      shake: widget.shake?.cell == cell ? widget.shake : null,
      reaction: widget.reaction?.cell == cell ? widget.reaction : null,
      highlighted: highlighted,
      milestone: widget.milestones.contains(cell),
      target: widget.hint == cell,
      hintKey: widget.hint == cell ? widget.hintCellKey : null,
      pulse: highlighted || widget.milestones.contains(cell)
          ? widget.hintPulse
          : 0,
      patterns: widget.showRegionPatterns,
      taps: widget.onCellPressed != null,
      novas: widget.onNovaPressed != null,
      reduced: MediaQuery.disableAnimationsOf(context),
      locale: Localizations.maybeLocaleOf(context),
    );
    final cached = _cells[cell];
    if (cached != null && cached.signature == signature) return cached.child;
    final child = _buildCell(context, cell, colors);
    _cells[cell] = (signature: signature, child: child);
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.session.puzzle;
    final colors = _colors;

    final surface = RepaintBoundary(
      child: CustomPaint(
        painter: _BoardSurface(count: board.size),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space12,
              ),
              child: GameplayRegionProgress(session: widget.session),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.gridPadding),
              child: GameplayTouchSurface(
                size: board.size,
                epoch: widget.gestureEpoch,
                onTap: widget.onCellPressed == null
                    ? null
                    : (cell) {
                        _finishEntrance();
                        widget.onCellPressed!(cell);
                      },
                onDoubleTap: widget.onNovaPressed == null
                    ? null
                    : (cell) {
                        _finishEntrance();
                        widget.onNovaPressed!(cell);
                      },
                onSwipe: widget.onSwipeCell == null
                    ? null
                    : (cell, add) {
                        _finishEntrance();
                        widget.onSwipeCell!(cell, add);
                      },
                swipeModeAt: (cell) =>
                    widget.session.marks[cell] == CellMark.nova ||
                        widget.session.rejectedCells.contains(cell)
                    ? null
                    : widget.session.marks[cell] != CellMark.cross,
                child: Column(
                  children: [
                    for (var row = 0; row < board.size; row++) ...[
                      if (row > 0) const SizedBox(height: AppTokens.gridGap),
                      Row(
                        children: [
                          for (
                            var column = 0;
                            column < board.size;
                            column++
                          ) ...[
                            if (column > 0)
                              const SizedBox(width: AppTokens.gridGap),
                            Expanded(
                              child: GameplayCellEntrance(
                                animation: _entrance,
                                row: row,
                                column: column,
                                size: board.size,
                                restarting: _restarting,
                                child: _cell(context, (
                                  row: row,
                                  column: column,
                                ), colors),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return GameplayNovaPlayback(
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0,
          end: widget.session.status == PuzzleStatus.completed ? 1 : 0,
        ),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        child: surface,
        builder: (context, progress, child) => CustomPaint(
          foregroundPainter: _CompletionGlow(
            widget.session.status == PuzzleStatus.completed ? progress : 0,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    CellPosition cell,
    Map<int, NovaRegionTone> colors,
  ) {
    final region = widget.session.puzzle.regionAt(cell);
    final mark = widget.session.marks[cell];
    final error = widget.shake;
    final isMistake =
        widget.session.rejectedCells.contains(cell) || error?.cell == cell;
    final isHint = widget.hint == cell || widget.highlights.contains(cell);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final character = !reduced && widget.reaction?.cell == cell
        ? widget.reaction
        : null;
    final state = isMistake
        ? 'Incorrect placement'
        : switch (mark) {
            CellMark.nova => 'Nova',
            CellMark.cross => 'Marked X',
            null => 'Empty',
          };
    Widget buildTile(Animation<double>? reveal) => RepaintBoundary(
      child: NovaGridCell(
        key: ValueKey(cell),
        region: colors[region]!,
        hintPulse: widget.hintPulse,
        showRegionPattern: widget.showRegionPatterns,
        regionPattern: GameplayRegionPattern(region: colors[region]!),
        showRegionLabel: false,
        // 12.5% more Nova area; the existing video inset/reveal stays contained.
        markFraction: mark == CellMark.nova ? .99 : .82,
        regionLabel: '$region',
        semanticLabel: isHint
            ? context.strings.hintCellDescription(
                context.strings.cellDescription(
                  cell.row + 1,
                  cell.column + 1,
                  region,
                  localize(context, state),
                ),
              )
            : context.strings.cellDescription(
                cell.row + 1,
                cell.column + 1,
                region,
                localize(context, state),
              ),
        appearance: isMistake
            ? NovaCellAppearance.mistake
            : isHint || widget.milestones.contains(cell)
            ? NovaCellAppearance.hint
            : NovaCellAppearance.normal,
        restoreRegionOnMistake: isMistake,
        markReveal: reveal,
        pointerInput: false,
        onPressed: widget.onCellPressed == null
            ? null
            : () {
                _finishEntrance();
                widget.onCellPressed!(cell);
              },
        onDoubleTap: widget.onNovaPressed == null
            ? null
            : () {
                _finishEntrance();
                widget.onNovaPressed!(cell);
              },
        mark: isMistake
            ? GameplayCross(color: AppColors.error, animation: reveal)
            : _BoardMark(
                mark: mark,
                reaction: character,
                onReactionCompleted: (value) =>
                    widget.onReactionCompleted(value),
              ),
      ),
    );
    final tile = isMistake
        ? GameplayMistakeCell(
            event: error?.cell == cell ? error!.event : null,
            builder: buildTile,
          )
        : buildTile(null);
    if (widget.hint == cell) {
      return KeyedSubtree(key: widget.hintCellKey, child: tile);
    }
    return tile;
  }
}

class _BoardMark extends StatefulWidget {
  const _BoardMark({
    required this.mark,
    required this.reaction,
    required this.onReactionCompleted,
  });

  final CellMark? mark;
  final GameplayReaction? reaction;
  final ValueChanged<GameplayReaction> onReactionCompleted;

  @override
  State<_BoardMark> createState() => _BoardMarkState();
}

/// One clock and at most one glyph per cell, even when rapidly reversing a
/// swipe. Cancelling/replacing motion never queues outgoing switcher children.
class _BoardMarkState extends State<_BoardMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  CellMark? _visible;
  bool _removing = false;
  Timer? _reactionTimer;

  @override
  void initState() {
    super.initState();
    _visible = widget.mark;
    _motion = AnimationController(vsync: this, value: 1)
      ..addStatusListener(_settled);
  }

  void _settled(AnimationStatus status) {
    if (status == AnimationStatus.completed && _removing && mounted) {
      setState(() => _visible = null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _visible = widget.mark;
      _removing = false;
      _motion.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _BoardMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction != widget.reaction) {
      _reactionTimer?.cancel();
      final reaction = widget.reaction;
      if (reaction != null) {
        _reactionTimer = Timer(GameplayMotion.novaReveal, () {
          if (mounted && widget.reaction == reaction) {
            widget.onReactionCompleted(reaction);
          }
        });
      }
    }
    if (oldWidget.mark == widget.mark) return;
    _removing = widget.mark == null;
    if (!_removing) _visible = widget.mark;
    if (MediaQuery.disableAnimationsOf(context)) {
      _visible = widget.mark;
      _removing = false;
      _motion.value = 1;
      return;
    }
    _motion.duration = _removing
        ? GameplayMotion.markOut
        : widget.mark == CellMark.nova
        ? GameplayMotion.novaReveal
        : GameplayMotion.crossIn;
    _motion.forward(from: 0);
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nova = _visible == CellMark.nova ? const GameplayNovaImage() : null;
    return AnimatedBuilder(
      animation: _motion,
      child: nova,
      builder: (context, nova) {
        if (_visible == null) return const SizedBox.shrink();
        final time = _motion.value;
        final removing = _removing;
        final progress = Curves.easeOutCubic.transform(time);
        final isNova = _visible == CellMark.nova;
        final scale = removing
            ? 1 - .16 * progress
            : isNova
            ? .82 + .18 * Curves.easeOutBack.transform(time)
            : .72 + .28 * Curves.easeOutBack.transform(time);
        final glyph = isNova
            ? nova!
            : GameplayCross(
                color: AppColors.surface,
                progress: removing ? 1 : progress,
              );
        return Opacity(
          opacity: removing ? 1 - progress : progress,
          child: Transform(
            alignment: Alignment.center,
            transformHitTests: false,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0012)
              ..rotateY(isNova && !removing ? (1 - progress) * math.pi / 2 : 0)
              ..scaleByDouble(scale, scale, 1, 1),
            child: CustomPaint(
              foregroundPainter: isNova && !removing
                  ? _NovaSparkles(time)
                  : null,
              child: Center(child: glyph),
            ),
          ),
        );
      },
    );
  }
}

/// A single white silhouette: the progress tab overlaps the board surface.
class _BoardSurface extends CustomPainter {
  const _BoardSurface({required this.count});
  final int count;
  @override
  void paint(Canvas canvas, Size size) {
    final board = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 28, size.width, size.height - 28),
          const Radius.circular(22),
        ),
      );
    final tab = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (size.width - (count * 30.0 + 16).clamp(0, size.width - 24)) / 2,
            0,
            (count * 30.0 + 16).clamp(0, size.width - 24),
            48,
          ),
          const Radius.circular(22),
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.union, board, tab),
      Paint()..color = AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardSurface oldDelegate) =>
      count != oldDelegate.count;
}

/// Four brief glints share the existing reveal clock; no particle allocation
/// or extra ticker is needed for a discovered Nova.
class _NovaSparkles extends CustomPainter {
  const _NovaSparkles(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = math.sin(progress * math.pi);
    if (strength <= .001) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * .48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryEdge.withValues(alpha: strength * .35),
            AppColors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + math.pi / 4;
      final radius = size.shortestSide * (.22 + .23 * progress);
      final center =
          size.center(Offset.zero) +
          Offset(math.cos(angle), math.sin(angle)) * radius;
      final ray = size.shortestSide * .065 * strength;
      final path = Path()
        ..moveTo(center.dx, center.dy - ray)
        ..lineTo(center.dx + ray * .5, center.dy)
        ..lineTo(center.dx, center.dy + ray)
        ..lineTo(center.dx - ray * .5, center.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? AppColors.decorGold : AppColors.primary)
              .withValues(alpha: strength * .65),
      );
    }
  }

  @override
  bool shouldRepaint(_NovaSparkles oldDelegate) =>
      progress != oldDelegate.progress;
}

class _CompletionGlow extends CustomPainter {
  const _CompletionGlow(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = math.sin(progress * math.pi);
    if (strength <= .001 || size.height < 32) return;
    final outline = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 31, size.width - 6, size.height - 34),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..color = AppColors.primary.withValues(alpha: strength * .28),
    );
  }

  @override
  bool shouldRepaint(_CompletionGlow oldDelegate) =>
      progress != oldDelegate.progress;
}
