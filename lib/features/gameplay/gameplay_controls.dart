import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/widgets.dart';

import 'dart:math' as math;

import '../../core/animations/app_motion.dart';
import '../../core/services/feedback_services.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../game_engine/models/puzzle.dart';
import '../../shared/widgets/nova_glyph.dart';
import '../../shared/widgets/nova_heart_indicator.dart';
import '../../shared/widgets/nova_pressable.dart';
import '../../shared/characters/nova_assets.dart';
import 'gameplay_reward_effects.dart';

class GameplayHeader extends StatelessWidget {
  const GameplayHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onSettings,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _GameplayAction(
        label: 'Back',
        glyph: NovaGlyphKind.back,
        onPressed: onBack,
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
          child: Transform.translate(
            offset: const Offset(0, AppTokens.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NovaText(
                  AppInfo.name.toUpperCase(),
                  style: AppType.eyebrow.copyWith(fontSize: 10),
                ),
                Semantics(
                  header: true,
                  child: NovaText(
                    title,
                    textAlign: TextAlign.center,
                    style: AppType.screenTitle.copyWith(fontSize: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      _GameplayAction(
        label: 'Settings',
        glyph: NovaGlyphKind.settings,
        onPressed: onSettings,
      ),
    ],
  );
}

class GameplayAttempts extends StatelessWidget {
  const GameplayAttempts({super.key, required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final attempts = context.strings.attemptsLeft(remaining);
    return Column(
      children: [
        GameplayHeartBreak(
          remaining: remaining,
          child: NovaHeartIndicator(
            remaining: remaining,
            total: PuzzleSession.startingAttempts,
            spacing: AppTokens.space24 + AppTokens.space4,
            semanticLabel: attempts,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        ExcludeSemantics(
          child: NovaText(
            attempts,
            textAlign: TextAlign.center,
            style: AppType.label,
          ),
        ),
      ],
    );
  }
}

class GameplayRules extends StatelessWidget {
  const GameplayRules({super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.durationOf(context, const Duration(milliseconds: 1400)),
    builder: (context, progress, child) {
      final glow = MediaQuery.disableAnimationsOf(context) || progress >= 1
          ? 0.0
          : math.sin(progress * math.pi);
      return DecoratedBox(
        key: const ValueKey('gameplay rule card'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTokens.cardRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: glow * .35),
          ),
          boxShadow: [
            if (glow > 0)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: glow * .10),
                blurRadius: 10,
              ),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: _RuleBorderHighlight(progress, glow),
          child: child,
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTokens.space8,
        horizontal: AppTokens.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < 3; index++) ...[
            if (index > 0)
              const SizedBox(
                width: 1,
                height: 54,
                child: ColoredBox(color: AppColors.primaryEdge),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                ),
                child: Semantics(
                  label: [
                    context.strings.ruleRegion,
                    context.strings.ruleRows,
                    context.strings.ruleTouching,
                  ][index],
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        _RuleIllustration(rule: index),
                        const SizedBox(height: AppTokens.space4),
                        NovaText(
                          [
                            context.strings.everyRegion,
                            context.strings.rowColumnBadge,
                            context.strings.neverTouching,
                          ][index],
                          textAlign: TextAlign.center,
                          style: AppType.badge.copyWith(
                            color: AppColors.text,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// A short traveling light, rather than animating the illustrations or layout.
class _RuleBorderHighlight extends CustomPainter {
  const _RuleBorderHighlight(this.progress, this.glow);
  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (glow <= 0) return;
    final outline = Path()
      ..addRRect(AppTokens.cardRadius.toRRect(Offset.zero & size).deflate(1));
    final metric = outline.computeMetrics().first;
    final head = progress * metric.length;
    final tail = head - metric.length * .22;
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary.withValues(alpha: glow * .55);
    canvas.drawPath(metric.extractPath(math.max(0, tail), head), light);
    if (tail < 0) {
      canvas.drawPath(
        metric.extractPath(metric.length + tail, metric.length),
        light,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RuleBorderHighlight oldDelegate) =>
      progress != oldDelegate.progress || glow != oldDelegate.glow;
}

/// The center Nova excludes its region, row/column, or eight neighbors.
class _RuleIllustration extends StatelessWidget {
  const _RuleIllustration({required this.rule});
  final int rule;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 38,
    child: Column(
      children: [
        for (var row = 0; row < 3; row++)
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < 3; column++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(0.6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: AppColors
                              .regions[rule == 0 &&
                                      ((row == 1 && column == 2) ||
                                          (row == 2 && column > 0))
                                  ? NovaRegionTone.peach
                                  : NovaRegionTone.purple]!
                              .top,
                        ),
                        child: row == 1 && column == 1
                            ? const NovaArtworkImage(artwork: NovaArtwork.grid)
                            : ((rule == 2) ||
                                  (rule == 1 && (row == 1 || column == 1)) ||
                                  (rule == 0 &&
                                      !((row == 1 && column == 2) ||
                                          (row == 2 && column > 0))))
                            ? const Center(
                                child: NovaGlyph(
                                  NovaGlyphKind.cross,
                                  size: 8,
                                  color: AppColors.text,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class GameplayControls extends StatelessWidget {
  const GameplayControls({
    super.key,
    required this.hints,
    required this.novaUses,
    required this.onNova,
    required this.onHint,
    required this.onReset,
  });

  final int hints;
  final int novaUses;
  final VoidCallback? onNova;
  final VoidCallback? onHint;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PowerAction(
              label: context.strings.novaUsesRemaining(novaUses),
              caption: 'Nova',
              count: novaUses,
              onPressed: onNova,
              icon: const NovaArtworkImage(
                artwork: NovaArtwork.grid,
                width: 40,
                height: 40,
              ),
            ),
          ),
          Expanded(
            child: _PowerAction(
              label: context.strings.hintsRemaining(hints),
              caption: context.strings.hint,
              count: hints,
              onPressed: onHint,
              icon: const NovaGlyph(
                NovaGlyphKind.hint,
                color: AppColors.decorGold,
                size: 30,
              ),
            ),
          ),
          Expanded(
            child: _PowerAction(
              label: context.strings.reset,
              caption: context.strings.reset,
              onPressed: onReset,
              icon: const NovaGlyph(NovaGlyphKind.reset, size: 28),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PowerAction extends StatelessWidget {
  const _PowerAction({
    required this.label,
    required this.caption,
    required this.icon,
    required this.onPressed,
    this.count,
  });
  final String label;
  final String caption;
  final Widget icon;
  final int? count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => NovaPressable(
    label: label,
    radius: AppTokens.pillRadius,
    pressScale: AppMotion.iconPressScale,
    feedback: count == null ? FeedbackEvent.button : FeedbackEvent.uiClick,
    onPressed: onPressed,
    child: Opacity(
      opacity: onPressed == null ? AppTokens.disabledOpacity : 1,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: AppTokens.iconShadow,
                    ),
                    child: Center(child: icon),
                  ),
                ),
                if (count case final available?)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: AnimatedSwitcher(
                      duration: AppMotion.durationOf(
                        context,
                        AppMotion.controlDuration,
                      ),
                      child: Container(
                        key: ValueKey(available),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppTokens.pillRadius,
                        ),
                        child: NovaText(
                          '$available',
                          textAlign: TextAlign.center,
                          style: AppType.badge.copyWith(
                            color: AppColors.surface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space6),
          NovaText(caption, textAlign: TextAlign.center, style: AppType.label),
        ],
      ),
    ),
  );
}

class _GameplayAction extends StatelessWidget {
  const _GameplayAction({
    required this.label,
    required this.glyph,
    required this.onPressed,
  });

  final String label;
  final NovaGlyphKind glyph;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final icon = SizedBox.square(
      dimension: AppTokens.iconButtonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTokens.controlRadius,
          boxShadow: AppTokens.iconShadow,
        ),
        child: Center(
          child: NovaGlyph(
            glyph,
            color: enabled ? AppColors.primary : AppColors.disabledText,
          ),
        ),
      ),
    );
    return NovaPressable(
      label: label,
      radius: AppTokens.controlRadius,
      pressScale: AppMotion.iconPressScale,
      onPressed: onPressed,
      child: icon,
    );
  }
}
