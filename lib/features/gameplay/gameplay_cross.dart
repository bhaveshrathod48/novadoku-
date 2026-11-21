import 'package:flutter/widgets.dart';

/// A cell-sized mark with bold, soft ends, independent of toolbar icon sizing.
class GameplayCross extends StatelessWidget {
  const GameplayCross({
    super.key,
    required this.color,
    this.progress = 1,
    this.animation,
  });
  final Color color;
  final double progress;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CrossPainter(color, progress.clamp(0.0, 1.0), animation),
    child: const SizedBox.expand(),
  );
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color, this.progress, this.animation)
    : super(repaint: animation);
  final Color color;
  final double progress;
  final Animation<double>? animation;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation == null
        ? this.progress
        : Curves.easeOutCubic.transform(animation!.value.clamp(0.0, 1.0));
    final side = size.shortestSide;
    final origin = size.center(Offset.zero) - Offset(side / 2, side / 2);
    final ink = Paint()
      ..color = color
      ..strokeWidth = side * .24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void stroke(Offset start, Offset end, double amount) {
      if (amount <= 0) return;
      canvas.drawLine(
        origin + start,
        origin + Offset.lerp(start, end, amount)!,
        ink,
      );
    }

    stroke(
      Offset(side * .22, side * .22),
      Offset(side * .78, side * .78),
      (progress * 2).clamp(0.0, 1.0),
    );
    stroke(
      Offset(side * .78, side * .22),
      Offset(side * .22, side * .78),
      (progress * 2 - 1).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) =>
      color != oldDelegate.color ||
      progress != oldDelegate.progress ||
      animation != oldDelegate.animation;
}
