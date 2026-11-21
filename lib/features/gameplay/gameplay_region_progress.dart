import 'package:flutter/widgets.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../game_engine/models/puzzle.dart';
import '../../l10n/nova_localizations.dart';
import '../../shared/characters/nova_assets.dart';

Map<int, NovaRegionTone> gameplayRegionColors(PuzzleDefinition puzzle) {
  final regions = puzzle.regionIds.toSet().toList()..sort();
  return {
    for (final (index, region) in regions.indexed)
      region: NovaRegionTone.values[index],
  };
}

/// Uses precisely the same region-to-palette mapping as the board.
class GameplayRegionProgress extends StatelessWidget {
  const GameplayRegionProgress({super.key, required this.session});
  final PuzzleSession session;

  @override
  Widget build(BuildContext context) {
    final colors = gameplayRegionColors(session.puzzle);
    final completed = {
      for (final entry in session.marks.entries)
        if (entry.value == CellMark.nova) session.puzzle.regionAt(entry.key),
    };
    return Semantics(
      label: context.strings.foundCount(
        session.novasPlaced,
        session.puzzle.size,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SizedBox(
            width: (colors.length * 30.0 + 16).clamp(0, constraints.maxWidth),
            height: 36,
            child: Row(
              children: [
                for (final entry in colors.entries)
                  Expanded(
                    child: GameplayRegionIcon(
                      region: entry.key,
                      tone: entry.value,
                      completed: completed.contains(entry.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameplayRegionIcon extends StatelessWidget {
  const GameplayRegionIcon({
    super.key,
    required this.region,
    required this.tone,
    required this.completed,
  });
  final int region;
  final NovaRegionTone tone;
  final bool completed;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${context.strings.unitRegion(region)}. ${completed ? 'Nova' : context.strings.empty}',
    image: true,
    child: ExcludeSemantics(
      child: Center(
        child: SizedBox.square(
          dimension: 28,
          child: AnimatedSwitcher(
            duration: AppMotion.durationOf(context, AppMotion.cellPop),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation
                    .drive(CurveTween(curve: Curves.easeOutBack))
                    .drive(Tween(begin: .72, end: 1.0)),
                child: child,
              ),
            ),
            child: completed
                ? const NovaArtworkImage(
                    key: ValueKey(true),
                    artwork: NovaArtwork.grid,
                  )
                : ColorFiltered(
                    key: const ValueKey(false),
                    colorFilter: ColorFilter.mode(
                      AppColors.regions[tone]!.bottom,
                      BlendMode.srcIn,
                    ),
                    child: const NovaArtworkImage(artwork: NovaArtwork.grid),
                  ),
          ),
        ),
      ),
    ),
  );
}
