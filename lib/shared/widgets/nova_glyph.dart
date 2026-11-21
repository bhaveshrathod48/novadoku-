import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum NovaGlyphKind { settings, star, chevron, back, undo, hint, reset, cross }

class NovaGlyph extends StatelessWidget {
  const NovaGlyph(
    this.kind, {
    super.key,
    this.size = AppTokens.iconSize,
    this.color,
  });

  final NovaGlyphKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _NovaGlyphPainter(
        kind,
        color ??
            (kind == NovaGlyphKind.star
                ? AppColors.decorGold
                : AppColors.primary),
      ),
    ),
  );
}

class _NovaGlyphPainter extends CustomPainter {
  const _NovaGlyphPainter(this.kind, this.color);

  static const _center = Offset(12, 12);
  static final _paths = <NovaGlyphKind, Path>{
    NovaGlyphKind.star: Path()
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
      ..close(),
    NovaGlyphKind.chevron: Path()
      ..moveTo(10, 7)
      ..lineTo(14, 12)
      ..lineTo(10, 17),
    NovaGlyphKind.back: Path()
      ..moveTo(12.5, 6.5)
      ..lineTo(7, 12)
      ..lineTo(12.5, 17.5)
      ..moveTo(7.5, 12)
      ..lineTo(18, 12),
    NovaGlyphKind.undo: Path()
      ..moveTo(9.8, 3.8)
      ..lineTo(5.6, 8)
      ..lineTo(9.8, 12.2)
      ..moveTo(6, 8)
      ..lineTo(13, 8)
      ..cubicTo(20.8, 8, 21, 19, 13.9, 20.5),
    NovaGlyphKind.hint: Path()
      ..moveTo(9, 16.2)
      ..cubicTo(9, 13.5, 5.5, 12.6, 5.5, 8.6)
      ..cubicTo(5.5, 0.7, 18.5, 0.7, 18.5, 8.6)
      ..cubicTo(18.5, 12.6, 15, 13.5, 15, 16.2)
      ..lineTo(9, 16.2)
      ..moveTo(9.8, 19.1)
      ..lineTo(14.2, 19.1)
      ..moveTo(11.1, 21.5)
      ..lineTo(12.9, 21.5),
    NovaGlyphKind.reset: Path()
      ..moveTo(18.3, 7.8)
      ..cubicTo(16.8, 3.6, 11.3, 2.6, 7.9, 4.8)
      ..cubicTo(4, 7.4, 3.3, 13.3, 6.3, 17.1)
      ..cubicTo(9.3, 21.1, 15.2, 21.3, 18.4, 17.9)
      ..moveTo(18.3, 4.1)
      ..lineTo(18.3, 9.8)
      ..lineTo(13.2, 9.8),
    NovaGlyphKind.cross: Path()
      ..moveTo(6, 6)
      ..lineTo(18, 18)
      ..moveTo(18, 6)
      ..lineTo(6, 18),
  };

  final NovaGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final ink = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = kind == NovaGlyphKind.cross ? 2.7 : 1.6
      ..style = kind == NovaGlyphKind.star
          ? PaintingStyle.fill
          : PaintingStyle.stroke;

    if (kind == NovaGlyphKind.settings) {
      canvas.drawCircle(_center, 3.2, ink);
      canvas.drawCircle(_center, 7.2, ink);
      for (var spoke = 0; spoke < 8; spoke++) {
        final angle = spoke * math.pi / 4;
        final ray = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(_center + ray * 7.2, _center + ray * 11.1, ink);
      }
    } else {
      canvas.drawPath(_paths[kind]!, ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NovaGlyphPainter oldDelegate) =>
      kind != oldDelegate.kind || color != oldDelegate.color;
}
