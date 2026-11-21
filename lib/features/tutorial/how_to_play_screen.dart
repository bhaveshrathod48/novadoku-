import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/game_providers.dart';
import '../../app/router/app_route.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../shared/characters/nova_assets.dart';
import '../../shared/layouts/nova_page_header.dart';
import '../../shared/layouts/nova_scaffold.dart';
import '../../shared/widgets/nova_buttons.dart';
import '../../shared/widgets/nova_arrival.dart';
import '../../shared/widgets/nova_glyph.dart';
import '../../shared/widgets/nova_surfaces.dart';
import 'tutorial_nova.dart';
import '../../shared/widgets/nova_particle_backdrop.dart';

enum _Rule {
  rowAndColumn('Rows + columns', 'One Nova in every\nrow and column.'),
  region('Every region', 'One Nova in each\ncoloured region.'),
  touching('Never touching', 'Keep Novas apart,\neven diagonally.');

  const _Rule(this.title, this.description);
  final String title;
  final String description;
}

class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key, this.fromGameplay = false});

  final bool fromGameplay;

  void _play(BuildContext context, WidgetRef ref) {
    final state = ref.read(puzzleGameProvider);
    final active = state.game?.session;
    final day = fromGameplay ? active?.dailyDay : null;
    if (day != null) {
      context.goNamed(
        AppRoute.dailyGameplay.name,
        queryParameters: {'day': '$day'},
      );
    } else {
      final level =
          (fromGameplay ? active?.level : null) ?? state.campaignLevel;
      context.goNamed(
        AppRoute.gameplay.name,
        queryParameters: {'level': '$level'},
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => NovaScaffold(
    background: NovaBackgroundStyle.gameplay,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final shortScreen = constraints.maxHeight < 660;
        final gap = shortScreen ? AppTokens.space4 : AppTokens.space8;
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final portraitSize =
            (constraints.maxHeight - 650 - (textScale - 1) * 160).clamp(
              AppTokens.space32,
              AppTokens.characterTutorialSize,
            );
        return SingleChildScrollView(
          key: const ValueKey('tutorial vertical layout'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: gap),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NovaPageHeader(
                    label: 'HOW TO PLAY',
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.goNamed(AppRoute.home.name);
                      }
                    },
                  ),
                  SizedBox(height: gap),
                  Column(
                    children: [
                      NovaParticleBackdrop(
                        mood: NovaParticleMood.tutorial,
                        child: TutorialNova(
                          size: math.min(
                            portraitSize * 2,
                            constraints.maxWidth,
                          ),
                        ),
                      ),
                      SizedBox(height: gap),
                      NovaText(
                        'Small rules.\nBright possibilities.',
                        style: AppType.tutorialTitle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  Column(
                    children: [
                      for (final (index, rule) in _Rule.values.indexed) ...[
                        if (index > 0)
                          SizedBox(
                            height: shortScreen ? gap : AppTokens.space12,
                          ),
                        NovaArrival(
                          delay: Duration(milliseconds: index * 70),
                          child: _RuleCard(rule: rule, compact: shortScreen),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: gap),
                  NovaPrimaryButton(
                    label: 'Let’s play',
                    onPressed: () => _play(context, ref),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.compact});

  final _Rule rule;
  final bool compact;

  @override
  Widget build(BuildContext context) => NovaCard(
    padding: EdgeInsets.symmetric(
      horizontal: AppTokens.space20,
      vertical: compact ? AppTokens.space8 : AppTokens.space12,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact
            ? AppTokens.space48
            : AppTokens.tutorialCardHeight - 2 * AppTokens.space12,
      ),
      child: Row(
        children: [
          ExcludeSemantics(child: _RuleGrid(rule: rule)),
          const SizedBox(width: AppTokens.space24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NovaText(
                  rule.title,
                  style: AppType.sectionTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: AppTokens.space4),
                NovaText(
                  rule.description,
                  style: AppType.description.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RuleGrid extends StatelessWidget {
  const _RuleGrid({required this.rule});

  final _Rule rule;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.durationOf(context, AppMotion.tutorialDemonstration),
    builder: (context, progress, child) => CustomPaint(
      foregroundPainter: _RuleFocus(
        rule,
        MediaQuery.disableAnimationsOf(context) ? 1 : progress,
      ),
      child: child,
    ),
    child: Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: AppTokens.space2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: AppTokens.space2),
                _cell(row, column),
              ],
            ],
          ),
        ],
      ],
    ),
  );

  Widget _cell(int row, int column) => Container(
    width: AppTokens.tutorialCellSize,
    height: AppTokens.tutorialCellSize,
    decoration: BoxDecoration(
      color: rule == _Rule.region
          ? AppColors
                .regions[column == 2
                    ? NovaRegionTone.mint
                    : NovaRegionTone.pink]!
                .bottom
          : AppColors.segmentTrack,
      borderRadius: const BorderRadius.all(Radius.circular(AppTokens.space4)),
    ),
    child: switch ((row, column)) {
      (1, 1) => Transform.scale(
        scale: 1.24,
        child: const NovaArtworkImage(artwork: NovaArtwork.grid),
      ),
      (2, 2) when rule == _Rule.touching => const Center(
        child: NovaGlyph(
          NovaGlyphKind.cross,
          size: AppTokens.space12,
          color: AppColors.text,
        ),
      ),
      _ => null,
    },
  );
}

/// Briefly trace precisely the cells excluded by the center Nova. This is an
/// instructional overlay, not a second playable board or a repeating effect.
class _RuleFocus extends CustomPainter {
  const _RuleFocus(this.rule, this.progress);
  final _Rule rule;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = progress >= 1 ? 0.0 : math.sin(math.pi * progress);
    if (pulse <= 0) return;
    final step = (size.width + AppTokens.space2) / 3;
    final side = step - AppTokens.space2;
    final ink = Paint()
      ..color = AppColors.primary.withValues(alpha: pulse * .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        if (row == 1 && column == 1) continue;
        final excluded = switch (rule) {
          _Rule.rowAndColumn => row == 1 || column == 1,
          _Rule.region => column < 2,
          _Rule.touching => true,
        };
        if (excluded) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(column * step, row * step, side, side).deflate(.7),
              const Radius.circular(AppTokens.space4),
            ),
            ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RuleFocus oldDelegate) =>
      rule != oldDelegate.rule || progress != oldDelegate.progress;
}
