import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../../core/animations/app_motion.dart';
import '../../core/services/feedback_services.dart';
import '../../core/services/feedback_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../shared/widgets/nova_pressable.dart';

/// Three visible positions, with the selected unlocked level in the center.
class HomeLevelSelector extends StatefulWidget {
  const HomeLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.unlockedThrough,
    required this.completedLevels,
    required this.onSelected,
    this.enabled = true,
  });

  final int selectedLevel;
  final int unlockedThrough;
  final Set<int> completedLevels;
  final ValueChanged<int> onSelected;
  final bool enabled;

  @override
  State<HomeLevelSelector> createState() => _HomeLevelSelectorState();
}

class _HomeLevelSelectorState extends State<HomeLevelSelector> {
  int? _clickedPage;
  late final PageController _pages = PageController(
    initialPage: widget.selectedLevel - 1,
    viewportFraction: 1 / 3,
  );

  @override
  void didUpdateWidget(covariant HomeLevelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLevel != widget.selectedLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pages.hasClients) return;
        final page = widget.selectedLevel - 1;
        if (_pages.page!.round() != page) _select(page);
      });
    }
  }

  void _select(int page) {
    if (!widget.enabled || page < 0 || page >= widget.unlockedThrough) return;
    _clickedPage = _pages.hasClients && _pages.page!.round() != page
        ? page
        : null;
    final duration = AppMotion.durationOf(context, AppMotion.scaleDuration);
    if (duration == Duration.zero) {
      _pages.jumpToPage(page);
    } else {
      _pages
          .animateToPage(page, duration: duration, curve: AppMotion.enterCurve)
          .whenComplete(() {
            if (_clickedPage == page) _clickedPage = null;
          });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 244,
    height: AppTokens.minimumTarget,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: widget.selectedLevel == 1 ? 122 : 40,
          right: 40,
          child: Container(
            height: AppTokens.accentBorderWidth,
            color: Color.alphaBlend(
              AppColors.primary.withValues(alpha: 0.17),
              AppColors.segmentTrack,
            ),
          ),
        ),
        PageView.builder(
          key: const ValueKey('home level selector'),
          controller: _pages,
          physics: widget.enabled
              ? const _UnlockedLevelPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: widget.unlockedThrough + 1,
          onPageChanged: (page) {
            final level = page + 1;
            if (level <= widget.unlockedThrough &&
                (widget.completedLevels.contains(level) ||
                    level == widget.unlockedThrough)) {
              // Button selections already play through NovaPressable. A drag
              // changes the page directly and needs only the missing audio.
              if (_clickedPage == null && level != widget.selectedLevel) {
                FeedbackScope.play(context, FeedbackEvent.uiClick);
              }
              if (_clickedPage == page) _clickedPage = null;
              widget.onSelected(level);
            }
          },
          itemBuilder: (context, index) {
            final level = index + 1;
            final selected = level == widget.selectedLevel;
            final complete = widget.completedLevels.contains(level);
            final unlocked =
                level <= widget.unlockedThrough &&
                (complete || level == widget.unlockedThrough);
            return Center(
              child: NovaPressable(
                feedback: FeedbackEvent.selection,
                label: context.strings.levelStatus(
                  context.strings.level(level),
                  !unlocked
                      ? context.strings.locked
                      : complete
                      ? context.strings.completed
                      : context.strings.unlocked,
                ),
                selected: selected,
                onPressed: widget.enabled && unlocked
                    ? () => _select(index)
                    : null,
                radius: AppTokens.pillRadius,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(selected),
                  tween: Tween(begin: 0, end: 1),
                  duration: AppMotion.durationOf(
                    context,
                    AppMotion.scaleDuration,
                  ),
                  builder: (context, value, child) => Transform.scale(
                    scale: selected && !MediaQuery.disableAnimationsOf(context)
                        ? 1 + .045 * math.sin(math.pi * value)
                        : 1,
                    transformHitTests: false,
                    child: child,
                  ),
                  child: AnimatedContainer(
                    duration: AppMotion.durationOf(
                      context,
                      AppMotion.controlDuration,
                    ),
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(AppTokens.space8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.primary
                          : complete
                          ? AppColors.successSurface
                          : AppColors.surface,
                      gradient: selected ? AppColors.primaryGradient : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: NovaText(
                        '$level',
                        style: AppType.badge.copyWith(
                          fontSize: 22,
                          color: selected
                              ? AppColors.surface
                              : complete
                              ? AppColors.success
                              : AppColors.disabledText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

/// Keep the next locked indicator visible without allowing it to be centered.
class _UnlockedLevelPhysics extends ScrollPhysics {
  const _UnlockedLevelPhysics({super.parent});

  @override
  _UnlockedLevelPhysics applyTo(ScrollPhysics? ancestor) =>
      _UnlockedLevelPhysics(parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final limit = (position.maxScrollExtent - position.viewportDimension / 3)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (value > limit && value > position.pixels) {
      return value - (position.pixels > limit ? position.pixels : limit);
    }
    return super.applyBoundaryConditions(position, value);
  }
}
