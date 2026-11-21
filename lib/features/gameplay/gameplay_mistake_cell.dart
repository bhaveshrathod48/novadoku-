import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// One finite, cell-local clock. A cleared board-level shake never interrupts it.
class GameplayMistakeCell extends StatefulWidget {
  const GameplayMistakeCell({
    super.key,
    required this.event,
    required this.builder,
  });
  final int? event;
  final Widget Function(Animation<double> reveal) builder;
  static const appearanceMs = 250;
  static const holdMs = 200;
  static const crackMs = 350;
  static const breakMs = 500;
  static const heartEndMs = appearanceMs + holdMs + crackMs + breakMs;
  static const duration = Duration(milliseconds: heartEndMs + 170);
  @override
  State<GameplayMistakeCell> createState() => _GameplayMistakeCellState();
}

class _GameplayMistakeCellState extends State<GameplayMistakeCell>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: GameplayMistakeCell.duration,
    value: 1,
  );
  late final _reveal = _clock.drive(
    CurveTween(
      curve: Interval(
        GameplayMistakeCell.heartEndMs /
            GameplayMistakeCell.duration.inMilliseconds,
        1,
      ),
    ),
  );
  @override
  void initState() {
    super.initState();
    if (widget.event != null) _clock.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _clock.value = 1;
  }

  @override
  void didUpdateWidget(covariant GameplayMistakeCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != null && widget.event != oldWidget.event) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _clock.value = 1;
      } else {
        _clock.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    child: RepaintBoundary(
      child: Stack(
        children: [
          widget.builder(_reveal),
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: AppTokens.cellRadius,
                child: CustomPaint(painter: GameplayMistakePainter(_clock)),
              ),
            ),
          ),
        ],
      ),
    ),
    builder: (context, child) {
      final shake =
          (_clock.value * GameplayMistakeCell.duration.inMilliseconds / 270)
              .clamp(0.0, 1.0);
      return Transform.translate(
        offset: Offset(
          math.sin(shake * math.pi * 6) * math.pow(1 - shake, 1.4) * 5,
          0,
        ),
        child: child,
      );
    },
  );
}

class GameplayMistakePainter extends CustomPainter {
  GameplayMistakePainter(this.clock) : super(repaint: clock);
  final Animation<double> clock;
  @override
  void paint(Canvas canvas, Size size) {
    final ms = clock.value * GameplayMistakeCell.duration.inMilliseconds;
    if (ms >= GameplayMistakeCell.heartEndMs) return;
    double phase(double start, double span) =>
        ((ms - start) / span).clamp(0.0, 1.0);
    final flash =
        Curves.easeOutCubic.transform(phase(0, 110)) *
        (1 - Curves.easeInOutCubic.transform(phase(800, 500)));
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.errorSurface.withValues(alpha: flash * .94),
    );
    final heartFade =
        Curves.easeOutCubic.transform(phase(0, 250)) *
        (1 - Curves.easeInOutCubic.transform(phase(800, 500)));
    if (heartFade > 0) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      final scale =
          size.shortestSide *
          .027 *
          (.55 + .45 * Curves.easeOutBack.transform(phase(0, 250)));
      canvas.scale(scale);
      final heart = Path()
        ..moveTo(0, 8.5)
        ..cubicTo(-2, 7, -10, 2, -10, -3)
        ..cubicTo(-10, -10, -3, -11, 0, -6)
        ..cubicTo(3, -11, 10, -10, 10, -3)
        ..cubicTo(10, 2, 2, 7, 0, 8.5)
        ..close();
      final left = Path()
        ..moveTo(-20, -20)
        ..lineTo(0, -20)
        ..lineTo(0, -7)
        ..lineTo(-1.8, -3)
        ..lineTo(1.5, 0)
        ..lineTo(-1.3, 4)
        ..lineTo(0, 8.5)
        ..lineTo(0, 20)
        ..lineTo(-20, 20)
        ..close();
      final split = Curves.easeInOutCubic.transform(phase(800, 500));
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(side * split * 7, split * split * 4);
        canvas.rotate(side * split * .3);
        canvas.clipPath(
          side < 0
              ? left
              : Path.combine(
                  PathOperation.difference,
                  Path()..addRect(const Rect.fromLTRB(-20, -20, 20, 20)),
                  left,
                ),
        );
        canvas.drawPath(
          heart,
          Paint()..color = AppColors.error.withValues(alpha: heartFade),
        );
        canvas.restore();
      }
      if (ms >= 450 && ms < 850) {
        canvas.drawPath(
          Path()
            ..moveTo(0, -7)
            ..lineTo(-1.8, -3)
            ..lineTo(1.5, 0)
            ..lineTo(-1.3, 4)
            ..lineTo(0, 8.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = Curves.easeOutCubic.transform(phase(450, 350)) * 1.3
            ..strokeCap = StrokeCap.round
            ..color = AppColors.errorSurface.withValues(
              alpha: 1 - phase(800, 50),
            ),
        );
      }
      canvas.restore();
    }
    if (ms >= 800 && ms < 1300) {
      final t = phase(800, 500);
      for (var i = 0; i < 8; i++) {
        final a = i * 2.39996;
        final point =
            size.center(Offset.zero) +
            Offset(math.cos(a), math.sin(a)) *
                size.shortestSide *
                (.15 + .25 * t);
        canvas.drawCircle(
          point,
          size.shortestSide * .025 * (1 - t),
          Paint()..color = AppColors.error.withValues(alpha: 1 - t),
        );
      }
    }
  }

  @override
  bool shouldRepaint(GameplayMistakePainter old) => clock != old.clock;
}
