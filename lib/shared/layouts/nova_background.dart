import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../core/animations/app_motion.dart';

import 'dart:math' as math;

enum NovaBackgroundStyle { calm, hero, gameplay, daily }

class NovaBackground extends StatelessWidget {
  const NovaBackground({
    super.key,
    required this.child,
    this.style = NovaBackgroundStyle.calm,
  });

  final Widget child;
  final NovaBackgroundStyle style;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: RepaintBoundary(child: CustomPaint(painter: _Backdrop(style))),
      ),
      if (style == NovaBackgroundStyle.hero ||
          style == NovaBackgroundStyle.daily)
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.durationOf(
                  context,
                  AppMotion.backgroundSettle,
                ),
                builder: (context, progress, _) => CustomPaint(
                  painter: _Accents(
                    style,
                    MediaQuery.disableAnimationsOf(context) ? 1 : progress,
                  ),
                ),
              ),
            ),
          ),
        ),
      child,
    ],
  );
}

class _Backdrop extends CustomPainter {
  const _Backdrop(this.style);

  final NovaBackgroundStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final width = size.width;
    final height = size.height;
    final bounds = Offset.zero & size;
    final ink = Paint();

    canvas.save();
    canvas.clipRect(bounds);
    final daily = style == NovaBackgroundStyle.daily;
    if (style != NovaBackgroundStyle.hero && !daily) {
      final gameplay = style == NovaBackgroundStyle.gameplay;
      canvas.drawRect(
        bounds,
        gameplay
            ? (Paint()..color = AppColors.background)
            : (Paint()..shader = AppColors.calmGradient.createShader(bounds)),
      );
      canvas.drawCircle(
        Offset(width * 0.88, height * (gameplay ? 0.09 : 0.12)),
        width * 0.43,
        ink..color = AppColors.backgroundDecor,
      );
    } else {
      // The blue midpoint crosses the upper-right and lower-left corners.
      // Scale the gradient axis by the viewport so those corners stay blue on
      // narrow phones and on wider windows.
      final axis = Offset(1 / width, 1 / height);
      final end = axis * (2 / axis.distanceSquared);
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            end,
            AppColors.heroGradient.colors,
            AppColors.heroGradient.stops,
          ),
      );
      canvas.drawCircle(
        Offset(width * 0.88, height * 0.35),
        width * 0.30,
        ink..color = AppColors.heroViolet,
      );
      canvas.drawCircle(
        Offset(width * 0.50, height * 0.46),
        width * 0.43,
        ink..color = AppColors.heroOrb.withValues(alpha: 0.24),
      );
      canvas.drawCircle(
        Offset(width * 0.05, height * 0.61),
        width * 0.22,
        ink..color = AppColors.heroBlush,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Backdrop oldDelegate) =>
      style != oldDelegate.style;
}

/// Only the small existing accents repaint; gradients and pastel fields remain
/// cached. A finite settling drift returns to the original artwork positions.
class _Accents extends CustomPainter {
  const _Accents(this.style, this.progress);
  final NovaBackgroundStyle style;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final width = size.width;
    final height = size.height;
    final daily = style == NovaBackgroundStyle.daily;
    final drift = progress >= 1 ? 0.0 : math.sin(progress * math.pi) * 3;
    final ink = Paint();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawCircle(
      Offset(
        width * (daily ? 0.16 : 0.14),
        height * (daily ? 0.36 : 0.39) - drift,
      ),
      width * (daily ? 0.019 : 0.022),
      ink..color = AppColors.decorGold,
    );
    canvas.drawCircle(
      Offset(
        width * (daily ? 0.84 : 0.86),
        height * (daily ? 0.50 : 0.49) + drift,
      ),
      width * 0.015,
      ink..color = AppColors.decorMint,
    );
    if (!daily) {
      final starCenter = Offset(width * 0.81, height * 0.345 - drift * .5);
      final starRadius = width * 0.022;
      final star = Path()
        ..moveTo(0, -1)
        ..lineTo(0.30, -0.31)
        ..lineTo(1, -0.22)
        ..lineTo(0.52, 0.28)
        ..lineTo(0.61, 0.96)
        ..lineTo(0, 0.65)
        ..lineTo(-0.61, 0.96)
        ..lineTo(-0.52, 0.28)
        ..lineTo(-1, -0.22)
        ..lineTo(-0.30, -0.31)
        ..close();
      canvas.save();
      canvas.translate(starCenter.dx, starCenter.dy);
      canvas.scale(starRadius);
      canvas.drawPath(star, ink..color = AppColors.decorStar);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Accents oldDelegate) =>
      style != oldDelegate.style || progress != oldDelegate.progress;
}
