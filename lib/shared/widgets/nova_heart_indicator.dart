import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class NovaHeartIndicator extends StatelessWidget {
  const NovaHeartIndicator({
    super.key,
    required this.remaining,
    this.total = 3,
    this.spacing = AppTokens.space24,
    required this.semanticLabel,
  }) : assert(total > 0),
       assert(remaining >= 0 && remaining <= total);

  final int remaining;
  final int total;
  final double spacing;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    liveRegion: true,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTokens.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space32,
          vertical: AppTokens.space12,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: AppTokens.space8,
          children: [
            for (var index = 0; index < total; index++)
              TweenAnimationBuilder<double>(
                tween: Tween(end: index < remaining ? 1 : 0),
                duration: AppMotion.durationOf(context, AppMotion.heartLoss),
                curve: AppMotion.enterCurve,
                builder: (context, fill, child) => SizedBox.square(
                  dimension: AppTokens.heartSize,
                  child: Transform.scale(
                    scale: index < remaining
                        ? 1
                        : 1 + .22 * math.sin(fill * math.pi * 2),
                    child: CustomPaint(
                      painter: _HeartPainter(
                        Color.lerp(
                          AppColors.heartEmpty,
                          AppColors.heart,
                          fill,
                        )!,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 20, size.height / 20);
    final heart = Path()
      ..moveTo(10, 17.4)
      ..cubicTo(8.4, 16.5, 0.8, 11.8, 0.8, 6.8)
      ..cubicTo(0.8, 2.1, 6.4, 1, 10, 4.6)
      ..cubicTo(13.6, 1, 19.2, 2.1, 19.2, 6.8)
      ..cubicTo(19.2, 11.8, 11.6, 16.5, 10, 17.4)
      ..close();
    canvas.drawPath(heart, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      color != oldDelegate.color;
}
