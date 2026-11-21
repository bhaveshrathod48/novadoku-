import 'package:novadoku/l10n/nova_localizations.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import 'nova_pressable.dart';

enum NovaCellAppearance { normal, hint, mistake }

class NovaGridCell extends StatelessWidget {
  const NovaGridCell({
    super.key,
    required this.region,
    required this.regionLabel,
    required this.semanticLabel,
    this.onPressed,
    this.onDoubleTap,
    this.pointerInput = true,
    this.showRegionLabel = true,
    this.markFraction = AppTokens.gridMarkFraction,
    this.mark,
    this.showRegionPattern = false,
    this.regionPattern,
    this.restoreRegionOnMistake = false,
    this.markReveal,
    this.appearance = NovaCellAppearance.normal,
    this.hintPulse = 0,
  });

  final NovaRegionTone region;
  final String regionLabel;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onDoubleTap;
  final bool pointerInput;
  final bool showRegionLabel;
  final double markFraction;

  /// The caller owns the mark and its semantics, including any Nova artwork.
  final Widget? mark;
  final bool showRegionPattern;

  /// Optional feature-specific decoration, always beneath the cell mark.
  final Widget? regionPattern;
  final bool restoreRegionOnMistake;
  final Animation<double>? markReveal;
  final NovaCellAppearance appearance;
  final int hintPulse;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.regions[region]!;
    final isMistake = appearance == NovaCellAppearance.mistake;
    final errorSurface = isMistake && !restoreRegionOnMistake;
    Widget? glyph = mark;
    if (glyph != null && markReveal != null) {
      glyph = FadeTransition(
        opacity: markReveal!.drive(CurveTween(curve: Curves.easeOutCubic)),
        child: ScaleTransition(
          scale: markReveal!
              .drive(CurveTween(curve: Curves.easeOutBack))
              .drive(Tween(begin: .72, end: 1.0)),
          child: glyph,
        ),
      );
    }
    final glow = AppMotion.durationOf(context, AppMotion.hintHighlight);
    final Border border = switch (appearance) {
      NovaCellAppearance.normal ||
      NovaCellAppearance.hint => Border.all(color: palette.edge),
      NovaCellAppearance.mistake =>
        restoreRegionOnMistake
            ? Border.all(color: palette.edge)
            : Border.all(
                color: AppColors.error,
                width: AppTokens.accentBorderWidth,
              ),
    };

    return NovaPressable(
      label: semanticLabel,
      feedback: null,
      selected: appearance == NovaCellAppearance.hint ? true : null,
      onPressed: onPressed,
      onDoubleTap: onDoubleTap,
      pointerInput: pointerInput,
      doubleTapLabel: 'Place Nova',
      radius: AppTokens.cellRadius,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: AppMotion.durationOf(context, AppMotion.fadeDuration),
          decoration: BoxDecoration(
            borderRadius: AppTokens.cellRadius,
            border: border,
            color: errorSurface ? AppColors.errorSurface : palette.bottom,
            gradient: errorSurface
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(AppColors.cellSheen, palette.top),
                      palette.top,
                      palette.bottom,
                      palette.bottom,
                      palette.edge,
                    ],
                    stops: const [0, 0.10, 0.64, 0.94, 1],
                  ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (appearance == NovaCellAppearance.hint &&
                  glow != Duration.zero)
                TweenAnimationBuilder<double>(
                  key: ValueKey(hintPulse),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: glow,
                  builder: (context, time, _) => RepaintBoundary(
                    child: CustomPaint(painter: _HintGlow(time)),
                  ),
                ),
              if (appearance == NovaCellAppearance.hint)
                Padding(
                  padding: const EdgeInsets.all(AppTokens.space2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          AppTokens.cellRadius -
                          const BorderRadius.all(
                            Radius.circular(AppTokens.space2),
                          ),
                      border: Border.all(
                        color: AppColors.gridHighlight,
                        width: AppTokens.accentBorderWidth,
                      ),
                    ),
                  ),
                ),
              if (showRegionPattern && !errorSurface)
                ClipRRect(
                  borderRadius: AppTokens.cellRadius,
                  child:
                      regionPattern ??
                      CustomPaint(painter: _RegionPattern(region)),
                ),
              if (!isMistake && showRegionLabel)
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: FractionallySizedBox(
                    widthFactor: 0.52,
                    heightFactor: 0.40,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppTokens.space4,
                        top: AppTokens.space2,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.topStart,
                        child: NovaText(regionLabel, style: AppType.gridNumber),
                      ),
                    ),
                  ),
                ),
              if (mark != null || isMistake)
                FractionallySizedBox(
                  widthFactor: markFraction,
                  heightFactor: markFraction,
                  child: Center(
                    child:
                        glyph ??
                        FittedBox(
                          child: NovaText(
                            '!',
                            style: AppType.dialogTitle.copyWith(
                              color: AppColors.error,
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
}

class _HintGlow extends CustomPainter {
  const _HintGlow(this.time);

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = math.sin(time * math.pi);
    if (pulse <= 0 || size.shortestSide < 12) return;
    final border = AppTokens.cellRadius.toRRect(
      (Offset.zero & size).deflate(4),
    );
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.decorGold.withValues(alpha: pulse * .72);
    canvas.drawRRect(border, ink);
    canvas.drawRRect(
      border.deflate(3),
      ink..color = AppColors.gridHighlight.withValues(alpha: pulse * .27),
    );
  }

  @override
  bool shouldRepaint(_HintGlow oldDelegate) => time != oldDelegate.time;
}

class _RegionPattern extends CustomPainter {
  const _RegionPattern(this.region);

  final NovaRegionTone region;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.regionPatternInk
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (double y = 8; y + 3 < size.height; y += 11) {
      for (double x = 8; x + 3 < size.width; x += 11) {
        final center = Offset(x, y);
        switch (region) {
          case NovaRegionTone.pink:
            canvas.drawCircle(center, 1, ink);
          case NovaRegionTone.mint:
            canvas.drawLine(
              center - const Offset(2, 0),
              center + const Offset(2, 0),
              ink,
            );
          case NovaRegionTone.peach:
            canvas.drawLine(
              center - const Offset(0, 2),
              center + const Offset(0, 2),
              ink,
            );
          case NovaRegionTone.yellow:
            canvas.drawLine(
              center - const Offset(2, 2),
              center + const Offset(2, 2),
              ink,
            );
          case NovaRegionTone.blue:
            canvas.drawLine(
              center - const Offset(-2, 2),
              center + const Offset(-2, 2),
              ink,
            );
          case NovaRegionTone.purple:
            canvas.drawRect(
              Rect.fromCenter(center: center, width: 4, height: 4),
              ink,
            );
          case NovaRegionTone.lime:
            canvas.drawCircle(center, 2.4, ink);
          case NovaRegionTone.coral:
            canvas.drawLine(
              center - const Offset(2, 0),
              center + const Offset(2, 0),
              ink,
            );
            canvas.drawLine(
              center - const Offset(0, 2),
              center + const Offset(0, 2),
              ink,
            );
          case NovaRegionTone.indigo:
            canvas.drawLine(
              center - const Offset(2, 2),
              center + const Offset(2, 2),
              ink,
            );
            canvas.drawLine(
              center - const Offset(-2, 2),
              center + const Offset(-2, 2),
              ink,
            );
          case NovaRegionTone.rose:
            final triangle = Path()
              ..moveTo(x, y - 2)
              ..lineTo(x + 2.5, y + 2)
              ..lineTo(x - 2.5, y + 2)
              ..close();
            canvas.drawPath(triangle, ink);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RegionPattern oldDelegate) =>
      region != oldDelegate.region;
}
