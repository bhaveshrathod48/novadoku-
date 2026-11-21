import 'package:novadoku/l10n/nova_localizations.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/game_providers.dart';
import '../../app/router/app_route.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../game_engine/generator/puzzle_catalog.dart';
import 'daily_nova.dart';
import '../../shared/widgets/nova_particle_backdrop.dart';
import '../../shared/layouts/nova_page_header.dart';
import '../../shared/layouts/nova_scaffold.dart';
import '../../shared/widgets/nova_buttons.dart';
import '../../shared/widgets/nova_glyph.dart';
import '../../shared/widgets/nova_surfaces.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    if (ref.read(puzzleGameProvider).load.isLoading) return;
    final day = PuzzleCatalog.dayKey(DateTime.now());
    await ref.read(puzzleGameProvider.notifier).resumeDaily(day);
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final prepared = ref.read(puzzleGameProvider);
    if (prepared.load.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: NovaText('Could not load today’s puzzle. Try again.'),
        ),
      );
      return;
    }
    if (prepared.game?.session.dailyDay != day) return;
    context.goNamed(
      AppRoute.dailyGameplay.name,
      queryParameters: {'day': '$day'},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      puzzleGameProvider.select((state) => state.load.isLoading),
    );
    return NovaScaffold(
      background: NovaBackgroundStyle.daily,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final characterSize = math.min(
            constraints.maxWidth,
            (constraints.maxHeight - 456 - (textScale - 1) * 140).clamp(
              128.0,
              AppTokens.dailyCharacterSize,
            ),
          );
          return SingleChildScrollView(
            key: const ValueKey('daily vertical layout'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NovaPageHeader(
                      label: 'DAILY PLAY',
                      onBack: () => context.goNamed(AppRoute.home.name),
                      onSettings: () =>
                          context.pushNamed<void>(AppRoute.settings.name),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    NovaText(
                      'A fresh little\nchallenge.',
                      textAlign: TextAlign.center,
                      style: AppType.display,
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Semantics(
                      image: true,
                      label: localize(context, 'Nova ready to play'),
                      child: NovaParticleBackdrop(
                        mood: NovaParticleMood.daily,
                        child: DailyNova(size: characterSize),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    const _TodayCard(),
                    const SizedBox(height: AppTokens.space8),
                    NovaPrimaryButton(
                      label: 'Play daily puzzle',
                      loading: loading,
                      onPressed: () => _play(context, ref),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    NovaText(
                      'One Nova per row, column and region.\nNo touching, even diagonally.',
                      textAlign: TextAlign.center,
                      style: AppType.description.copyWith(height: 1.65),
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
}

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppTokens.dailyCardWidth),
    child: NovaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space8,
      ),
      child: Row(
        children: [
          const NovaGlyph(NovaGlyphKind.star),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Column(
              children: [
                NovaText(
                  'Today’s puzzle',
                  style: AppType.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space4),
                NovaText(
                  'Same rules. A new arrangement.',
                  style: AppType.label,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
