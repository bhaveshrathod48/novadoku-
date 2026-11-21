import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum HomeGlyphKind { settings, star, chevron }

class HomeGlyph extends StatelessWidget {
  const HomeGlyph(this.kind, {super.key, this.size = AppTokens.iconSize});

  final HomeGlyphKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _HomeGlyphPainter(kind)),
  );
}

class _HomeGlyphPainter extends CustomPainter {
  const _HomeGlyphPainter(this.kind);

  static const _center = Offset(12, 12);
  static final _star = Path()
    ..moveTo(12, 2)
    ..lineTo(15, 8.3)
    ..lineTo(22, 9.3)
    ..lineTo(17, 14.2)
    ..lineTo(18.2, 21)
    ..lineTo(12, 17.8)
    ..lineTo(5.8, 21)
    ..lineTo(7, 14.2)
    ..lineTo(2, 9.3)
    ..lineTo(9, 8.3)
    ..close();

  final HomeGlyphKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final ink = Paint()
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    switch (kind) {
      case HomeGlyphKind.settings:
        canvas.drawCircle(_center, 3.2, ink);
        canvas.drawCircle(_center, 7.2, ink);
        for (var spoke = 0; spoke < 8; spoke++) {
          final angle = spoke * math.pi / 4;
          final ray = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(_center + ray * 7.2, _center + ray * 11.1, ink);
        }
      case HomeGlyphKind.star:
        canvas.drawPath(
          _star,
          ink
            ..style = PaintingStyle.fill
            ..color = AppColors.decorGold,
        );
      case HomeGlyphKind.chevron:
        final arrow = Path()
          ..moveTo(10, 7)
          ..lineTo(14, 12)
          ..lineTo(10, 17);
        canvas.drawPath(arrow, ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeGlyphPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
