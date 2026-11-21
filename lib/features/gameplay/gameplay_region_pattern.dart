import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

enum GameplayPattern {
  pawPrint,
  catFace,
  fishbone,
  stars,
  yarnBall,
  butterfly,
  leaves,
  hearts,
  moon,
  novaBandana,
}

/// Static vector decorations, indexed by the same palette as the region grid.
class GameplayRegionPattern extends StatelessWidget {
  const GameplayRegionPattern({super.key, required this.region});
  final NovaRegionTone region;
  GameplayPattern get pattern => GameplayPattern.values[region.index];

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: CustomPaint(painter: GameplayPatternPainter(region)),
    ),
  );
}

class GameplayPatternPainter extends CustomPainter {
  const GameplayPatternPainter(this.region);
  final NovaRegionTone region;
  GameplayPattern get pattern => GameplayPattern.values[region.index];

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * .68;
    if (side <= 0) return;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 100);
    final ink = Paint()
      ..color = AppColors.regions[region]!.edge.withValues(alpha: .64)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(Path path, [double width = 5]) => canvas.drawPath(
      path,
      ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    void fill(Path path) =>
        canvas.drawPath(path, ink..style = PaintingStyle.fill);
    void oval(double x, double y, double w, double h) => canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      ink..style = PaintingStyle.fill,
    );
    Path heart(double x, double y, double s) => Path()
      ..moveTo(x, y + s * .48)
      ..cubicTo(x - s * .2, y + s * .3, x - s * .55, y, x - s * .48, y - s * .2)
      ..cubicTo(
        x - s * .4,
        y - s * .55,
        x - s * .1,
        y - s * .52,
        x,
        y - s * .28,
      )
      ..cubicTo(
        x + s * .1,
        y - s * .52,
        x + s * .4,
        y - s * .55,
        x + s * .48,
        y - s * .2,
      )
      ..cubicTo(x + s * .55, y, x + s * .2, y + s * .3, x, y + s * .48)
      ..close();
    Path star(double x, double y, double r) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final radius = i.isEven ? r : r * .45;
        final point = Offset(
          x + math.cos(a) * radius,
          y + math.sin(a) * radius,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path..close();
    }

    switch (pattern) {
      case GameplayPattern.pawPrint:
        fill(
          Path()
            ..moveTo(23, 66)
            ..cubicTo(22, 51, 37, 42, 50, 42)
            ..cubicTo(63, 42, 78, 51, 77, 66)
            ..cubicTo(78, 84, 63, 78, 50, 77)
            ..cubicTo(37, 78, 22, 84, 23, 66)
            ..close(),
        );
        oval(19, 39, 17, 23);
        oval(38, 24, 17, 24);
        oval(61, 24, 17, 24);
        oval(81, 39, 17, 23);
      case GameplayPattern.catFace:
        line(
          Path()
            ..moveTo(19, 44)
            ..lineTo(20, 15)
            ..quadraticBezierTo(21, 10, 39, 31)
            ..quadraticBezierTo(50, 26, 61, 31)
            ..quadraticBezierTo(79, 10, 80, 15)
            ..lineTo(81, 44)
            ..cubicTo(94, 83, 6, 83, 19, 44)
            ..close(),
        );
        oval(36, 49, 6, 8);
        oval(64, 49, 6, 8);
        fill(
          Path()
            ..moveTo(44, 58)
            ..lineTo(56, 58)
            ..lineTo(50, 64)
            ..close(),
        );
        line(
          Path()
            ..moveTo(50, 64)
            ..quadraticBezierTo(44, 73, 39, 66)
            ..moveTo(50, 64)
            ..quadraticBezierTo(56, 73, 61, 66),
          3,
        );
        line(
          Path()
            ..moveTo(28, 59)
            ..lineTo(8, 55)
            ..moveTo(27, 65)
            ..lineTo(10, 68)
            ..moveTo(72, 59)
            ..lineTo(92, 55)
            ..moveTo(73, 65)
            ..lineTo(90, 68),
          3,
        );
      case GameplayPattern.fishbone:
        canvas.translate(50, 50);
        canvas.rotate(-.55);
        canvas.translate(-50, -50);
        line(
          Path()
            ..moveTo(25, 50)
            ..lineTo(78, 50)
            ..moveTo(39, 35)
            ..lineTo(47, 50)
            ..lineTo(39, 65)
            ..moveTo(53, 35)
            ..lineTo(61, 50)
            ..lineTo(53, 65),
          5,
        );
        fill(
          Path()
            ..moveTo(22, 50)
            ..lineTo(7, 34)
            ..quadraticBezierTo(5, 50, 7, 66)
            ..close(),
        );
        line(
          Path()
            ..moveTo(72, 50)
            ..quadraticBezierTo(89, 28, 95, 50)
            ..quadraticBezierTo(89, 72, 72, 50)
            ..close(),
          5,
        );
      case GameplayPattern.stars:
        fill(star(43, 47, 30));
        fill(star(79, 24, 13));
        fill(star(77, 77, 17));
      case GameplayPattern.yarnBall:
        line(Path()..addOval(const Rect.fromLTWH(17, 17, 64, 64)), 5);
        line(
          Path()
            ..moveTo(19, 43)
            ..quadraticBezierTo(42, 15, 73, 30)
            ..moveTo(19, 57)
            ..quadraticBezierTo(42, 24, 80, 43)
            ..moveTo(26, 72)
            ..quadraticBezierTo(43, 39, 80, 55)
            ..moveTo(35, 78)
            ..quadraticBezierTo(54, 59, 74, 70),
          4,
        );
        line(
          Path()
            ..moveTo(22, 27)
            ..quadraticBezierTo(39, 42, 46, 72)
            ..moveTo(31, 20)
            ..quadraticBezierTo(54, 35, 62, 77),
          4,
        );
        line(
          Path()
            ..moveTo(76, 68)
            ..cubicTo(101, 74, 72, 92, 94, 85),
          4,
        );
      case GameplayPattern.butterfly:
        fill(
          Path()
            ..moveTo(48, 47)
            ..cubicTo(25, 3, 4, 19, 17, 46)
            ..quadraticBezierTo(18, 54, 35, 55)
            ..cubicTo(1, 61, 22, 94, 47, 64)
            ..close(),
        );
        fill(
          Path()
            ..moveTo(52, 47)
            ..cubicTo(75, 3, 96, 19, 83, 46)
            ..quadraticBezierTo(82, 54, 65, 55)
            ..cubicTo(99, 61, 78, 94, 53, 64)
            ..close(),
        );
        line(
          Path()
            ..moveTo(50, 38)
            ..lineTo(50, 74)
            ..moveTo(50, 38)
            ..quadraticBezierTo(46, 28, 40, 29)
            ..moveTo(50, 38)
            ..quadraticBezierTo(54, 28, 60, 29),
          4,
        );
      case GameplayPattern.leaves:
        line(
          Path()
            ..moveTo(25, 85)
            ..quadraticBezierTo(48, 59, 76, 18),
          4,
        );
        fill(
          Path()
            ..moveTo(39, 69)
            ..quadraticBezierTo(12, 60, 26, 31)
            ..quadraticBezierTo(49, 39, 39, 69)
            ..close(),
        );
        fill(
          Path()
            ..moveTo(49, 56)
            ..quadraticBezierTo(54, 23, 81, 16)
            ..quadraticBezierTo(82, 42, 49, 56)
            ..close(),
        );
        fill(
          Path()
            ..moveTo(33, 78)
            ..quadraticBezierTo(53, 54, 80, 60)
            ..quadraticBezierTo(64, 85, 33, 78)
            ..close(),
        );
      case GameplayPattern.hearts:
        fill(heart(28, 29, 32));
        fill(heart(73, 29, 32));
        fill(heart(28, 73, 32));
        fill(heart(73, 73, 32));
      case GameplayPattern.moon:
        fill(
          Path.combine(
            PathOperation.difference,
            Path()..addOval(const Rect.fromLTWH(15, 12, 72, 72)),
            Path()..addOval(const Rect.fromLTWH(40, 4, 65, 65)),
          ),
        );
        fill(star(75, 22, 10));
        fill(star(85, 62, 7));
      case GameplayPattern.novaBandana:
        final scarf = Path()
          ..moveTo(14, 27)
          ..quadraticBezierTo(50, 17, 86, 27)
          ..lineTo(55, 84)
          ..quadraticBezierTo(50, 91, 45, 84)
          ..close();
        final n = Path()
          ..moveTo(34, 63)
          ..lineTo(41, 37)
          ..lineTo(48, 37)
          ..lineTo(58, 53)
          ..lineTo(62, 37)
          ..lineTo(69, 37)
          ..lineTo(62, 67)
          ..lineTo(55, 67)
          ..lineTo(45, 51)
          ..lineTo(41, 67)
          ..lineTo(34, 67)
          ..close();
        fill(Path.combine(PathOperation.difference, scarf, n));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GameplayPatternPainter old) => region != old.region;
}
