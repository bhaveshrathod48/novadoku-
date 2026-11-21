import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/animations/app_motion.dart';
import '../../core/services/feedback_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import 'nova_pressable.dart';

class NovaToggle extends StatelessWidget {
  const NovaToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onLabel = 'On',
    this.offLabel = 'Off',
    this.playFeedback = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String onLabel;
  final String offLabel;
  final bool playFeedback;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.durationOf(context, AppMotion.controlDuration);
    final disabled = onChanged == null;
    return NovaPressable(
      label: label,
      button: false,
      feedback: playFeedback ? FeedbackEvent.selection : null,
      toggled: value,
      onPressed: disabled ? null : () => onChanged!(!value),
      radius: AppTokens.pillRadius,
      child: SizedBox(
        width: AppTokens.switchWidth,
        height: AppTokens.minimumTarget,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.enterCurve,
            height: AppTokens.switchHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6),
            decoration: BoxDecoration(
              color: value && !disabled
                  ? AppColors.primary
                  : AppColors.disabled,
              borderRadius: AppTokens.pillRadius,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: value
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space2,
                    ),
                    child: SizedBox(
                      width:
                          AppTokens.switchWidth -
                          AppTokens.switchThumb -
                          AppTokens.space16,
                      height: AppTokens.switchHeight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: NovaText(
                          value ? onLabel : offLabel,
                          style: AppType.label.copyWith(
                            color: value && !disabled
                                ? AppColors.surface
                                : AppColors.disabledText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: duration,
                  curve: AppMotion.enterCurve,
                  alignment: value
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: const SizedBox.square(
                    dimension: AppTokens.switchThumb,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
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

class NovaSegmentedControl<T extends Object> extends StatelessWidget {
  const NovaSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// The iteration order defines the display order.
  final Map<T, String> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    assert(options.length >= 2 && options.containsKey(value));
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.segmentTrack,
        borderRadius: AppTokens.controlRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Row(
          children: [
            for (final option in options.entries)
              Expanded(
                key: ValueKey(option.key),
                child: NovaPressable(
                  feedback: FeedbackEvent.selection,
                  label: option.value,
                  selected: option.key == value,
                  radius: AppTokens.controlRadius,
                  onPressed: onChanged == null
                      ? null
                      : () {
                          if (option.key != value) onChanged!(option.key);
                        },
                  child: AnimatedContainer(
                    duration: AppMotion.durationOf(
                      context,
                      AppMotion.controlDuration,
                    ),
                    curve: AppMotion.enterCurve,
                    constraints: const BoxConstraints(
                      minHeight: AppTokens.minimumTarget,
                    ),
                    padding: const EdgeInsets.all(AppTokens.space8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppTokens.controlRadius,
                      color: option.key == value
                          ? onChanged == null
                                ? AppColors.disabled
                                : AppColors.primary
                          : AppColors.transparent,
                      gradient: option.key == value && onChanged != null
                          ? AppColors.primaryGradient
                          : null,
                    ),
                    child: NovaText(
                      option.value,
                      style: AppType.secondaryButton.copyWith(
                        color: onChanged == null
                            ? AppColors.disabledText
                            : option.key == value
                            ? AppColors.surface
                            : AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
