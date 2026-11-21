import 'package:novadoku/l10n/nova_localizations.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/feedback_services.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../game_engine/hints/hint_engine.dart';
import '../../l10n/hint_localizations.dart';
import '../../game_engine/models/puzzle.dart';
import '../../game_engine/validator/puzzle_validator.dart';
import '../../shared/dialogs/nova_modal.dart';
import '../../shared/widgets/nova_buttons.dart';
import '../../shared/widgets/nova_celebration.dart';
import '../../shared/widgets/nova_glyph.dart';
import '../../shared/widgets/nova_surfaces.dart';
import 'try_again_nova.dart';
import 'level_complete_nova.dart';
import 'hint_nova.dart';
import '../../shared/widgets/nova_particle_backdrop.dart';

enum GameplayOutcomeAction { retry, next, home }

abstract final class GameplayDialogs {
  static Future<bool?> reset(BuildContext context) => NovaDialog.show<bool>(
    context,
    builder: (context) => NovaDialog(
      title: context.strings.restartPuzzle,
      content: NovaText(
        context.strings.restartDescription,
        textAlign: TextAlign.center,
        style: AppType.description,
      ),
      actions: [
        NovaPrimaryButton(
          label: context.strings.reset,
          onPressed: () => Navigator.pop(context, true),
        ),
        NovaTextButton(
          label: context.strings.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );

  static Future<bool?> hint(
    BuildContext context,
    PuzzleHint preview, {
    required GlobalKey sheetKey,
  }) => _hintSheet(
    context,
    sheetKey: sheetKey,
    explanation: (context) => NovaHintText(
      hint: preview,
      style: AppType.description.copyWith(height: 1.65),
    ),
  );

  /// Describe the first actual smart-hint edit. The unchanged engine can mark
  /// up to four excluded cells, or reveal a Nova when no such notes remain.
  static Future<bool?> smartHint(
    BuildContext context,
    PuzzleSession before,
    PuzzleSession after, {
    required GlobalKey sheetKey,
  }) => _hintSheet(
    context,
    sheetKey: sheetKey,
    explanation: (context) {
      final edit = after.marks.entries.firstWhere(
        (entry) => before.marks[entry.key] != entry.value,
      );
      final cell = edit.key;
      final strings = context.strings;
      String text;
      if (edit.value == CellMark.nova) {
        text =
            '${strings.placeNova}:\n${strings.unitRow(cell.row + 1)}, '
            '${strings.unitColumn(cell.column + 1)}.';
      } else {
        final placed = before.marks.entries
            .where((entry) => entry.value == CellMark.nova)
            .map((entry) => entry.key);
        final reason = switch (PuzzleValidator.conflict(
          before.puzzle,
          cell,
          placed,
        )) {
          PlacementConflict.row => strings.hintRow(cell.row + 1),
          PlacementConflict.column => strings.hintColumn(cell.column + 1),
          PlacementConflict.region => strings.hintRegion(
            before.puzzle.regionAt(cell),
          ),
          PlacementConflict.touching => strings.hintTouching,
          null => throw StateError('Smart hint must have a proven exclusion.'),
        };
        text = '$reason\n${strings.hintActionX(cell.row + 1, cell.column + 1)}';
      }
      return Text(text, style: AppType.description.copyWith(height: 1.65));
    },
  );

  static Future<bool?> _hintSheet(
    BuildContext context, {
    required GlobalKey sheetKey,
    required WidgetBuilder explanation,
  }) {
    var answered = false;
    void close(BuildContext context, bool apply) {
      if (answered || ModalRoute.of(context)?.isCurrent != true) return;
      answered = true;
      Navigator.pop(context, apply);
    }

    return NovaBottomSheet.show<bool>(
      context,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              AppTokens.hintSheetHeightFraction,
        ),
        child: NovaBottomSheet(
          key: sheetKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NovaBadge(label: 'HINT'),
                        const SizedBox(height: AppTokens.space8),
                        NovaText('A little nudge', style: AppType.dialogTitle),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: AppTokens.space8),
                    child: HintNova(size: AppTokens.characterHintSize),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              explanation(context),
              const SizedBox(height: AppTokens.space40 + AppTokens.space4),
              NovaPrimaryButton(
                label: 'Apply hint',
                feedback: FeedbackEvent.uiClick,
                onPressed: () => close(context, true),
              ),
              const SizedBox(height: AppTokens.space12),
              NovaTextButton(
                label: 'Cancel',
                onPressed: () => close(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> leave(BuildContext context) => NovaDialog.show<bool>(
    context,
    position: NovaDialogPosition.lower,
    builder: (context) => NovaDialog(
      title: 'Take a break?',
      titleGap: AppTokens.space16,
      actionGap: AppTokens.space48,
      bottomPadding: AppTokens.space48 + AppTokens.space6,
      content: NovaText(
        'Your puzzle will be here\nwhen you return.',
        textAlign: TextAlign.center,
        style: AppType.body.copyWith(
          color: AppColors.secondaryText,
          height: 1.55,
        ),
      ),
      actions: [
        NovaPrimaryButton(
          label: 'Keep playing',
          onPressed: () => Navigator.pop(context, false),
        ),
        NovaSecondaryButton(
          label: 'Save and leave',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  static Future<GameplayOutcomeAction?> outcome(
    BuildContext context,
    PuzzleSession session, {
    required bool celebrate,
  }) {
    final failed = session.status == PuzzleStatus.failed;
    final next = session.unlockedLevel != null;
    final action = failed
        ? (label: 'Try again', value: GameplayOutcomeAction.retry)
        : next
        ? (label: 'Next level', value: GameplayOutcomeAction.next)
        : null;
    return NovaDialog.show<GameplayOutcomeAction>(
      context,
      position: NovaDialogPosition.lower,
      dismissible: false,
      builder: (context) => PopScope<GameplayOutcomeAction>(
        canPop: false,
        child: NovaDialog(
          leading: _ResultArtwork(
            failed: failed,
            celebrate: celebrate && !failed,
          ),
          title: failed ? 'One more try?' : 'Beautifully done.',
          actionGap: AppTokens.space32,
          bottomPadding: AppTokens.space12,
          content: NovaText(
            failed
                ? 'A fresh start. A new perspective.\nYou have got this.'
                : '${context.strings.allFound(session.puzzle.size)}${next ? '\n${context.strings.nextWaiting}' : ''}',
            textAlign: TextAlign.center,
            style: AppType.description.copyWith(height: 1.65),
          ),
          actions: [
            if (action != null)
              NovaPrimaryButton(
                label: action.label,
                onPressed: () => Navigator.pop(context, action.value),
              ),
            NovaTextButton(
              label: 'Back home',
              onPressed: () =>
                  Navigator.pop(context, GameplayOutcomeAction.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultArtwork extends StatelessWidget {
  const _ResultArtwork({required this.failed, required this.celebrate});

  final bool failed;
  final bool celebrate;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      NovaBadge(
        label: failed ? 'A FRESH START' : 'PUZZLE COMPLETE',
        tone: failed ? NovaBadgeTone.lavender : NovaBadgeTone.success,
      ),
      const SizedBox(height: AppTokens.space12),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            constraints.maxWidth,
            AppTokens.resultPanelWidth,
          );
          final height =
              width * AppTokens.resultPanelHeight / AppTokens.resultPanelWidth;
          return Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: AppTokens.resultPanelRadius,
              gradient: AppColors.resultGradient,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: NovaParticleBackdrop(
                    mood: failed
                        ? NovaParticleMood.comforting
                        : NovaParticleMood.victory,
                    child: const SizedBox.expand(),
                  ),
                ),
                if (celebrate)
                  const Positioned.fill(
                    child: ClipRect(child: NovaCelebration()),
                  ),
                if (failed)
                  TryAgainNova(
                    size: math.min(height, AppTokens.characterResultSize),
                  )
                else
                  LevelCompleteNova(
                    size: math.min(height, AppTokens.characterResultSize),
                  ),
                if (!failed) ...[
                  const Align(
                    alignment: Alignment(-0.96, -0.27),
                    child: _AccentDot(color: AppColors.decorGold),
                  ),
                  const Align(
                    alignment: Alignment(0.96, 0.23),
                    child: _AccentDot(color: AppColors.decorMint),
                  ),
                  const Align(
                    alignment: Alignment(0.91, -0.72),
                    child: NovaGlyph(
                      NovaGlyphKind.star,
                      color: AppColors.decorStar,
                      size: AppTokens.space20,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppTokens.space8,
    child: DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}
