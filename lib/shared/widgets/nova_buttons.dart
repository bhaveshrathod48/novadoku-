import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/services/feedback_services.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import 'nova_loading_indicator.dart';
import 'nova_pressable.dart';

class NovaPrimaryButton extends StatelessWidget {
  const NovaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.feedback = FeedbackEvent.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final FeedbackEvent? feedback;

  @override
  Widget build(BuildContext context) => _LabelButton(
    label: label,
    onPressed: onPressed,
    style: _ButtonStyle.primary,
    loading: loading,
    feedback: feedback,
  );
}

class NovaSecondaryButton extends StatelessWidget {
  const NovaSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => _LabelButton(
    label: label,
    onPressed: onPressed,
    style: _ButtonStyle.secondary,
    loading: loading,
  );
}

class NovaTextButton extends StatelessWidget {
  const NovaTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => _LabelButton(
    label: label,
    onPressed: onPressed,
    style: _ButtonStyle.text,
    textStyle: textStyle,
  );
}

enum _ButtonStyle { primary, secondary, text }

class _LabelButton extends StatelessWidget {
  const _LabelButton({
    required this.label,
    required this.onPressed,
    required this.style,
    this.feedback = FeedbackEvent.button,
    this.loading = false,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final _ButtonStyle style;
  final FeedbackEvent? feedback;
  final bool loading;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    final primary = style == _ButtonStyle.primary;
    final labelStyle =
        textStyle ??
        switch (style) {
          _ButtonStyle.primary => AppType.primaryButton,
          _ButtonStyle.secondary => AppType.secondaryButton,
          _ButtonStyle.text => AppType.secondaryButton.copyWith(
            color: AppColors.primary,
          ),
        };
    final minHeight = switch (style) {
      _ButtonStyle.primary => AppTokens.primaryButtonHeight,
      _ButtonStyle.secondary => AppTokens.secondaryButtonHeight,
      _ButtonStyle.text => AppTokens.minimumTarget,
    };
    final radius = AppTokens.buttonRadius;
    return NovaPressable(
      label: loading
          ? context.strings.busyLabel(localize(context, label))
          : label,
      busy: loading,
      feedback: feedback,
      onPressed: loading ? null : onPressed,
      radius: radius,
      pressScale: AppMotion.buttonPressScale,
      pressOffset: style == _ButtonStyle.text
          ? Offset.zero
          : AppMotion.buttonPressOffset,
      child: Container(
        constraints: BoxConstraints(
          minHeight: minHeight,
          minWidth: AppTokens.minimumTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: switch (style) {
            _ButtonStyle.primary when disabled => AppColors.disabled,
            _ButtonStyle.secondary =>
              disabled ? AppColors.disabled : AppColors.surface,
            _ => null,
          },
          gradient: primary && !disabled ? AppColors.primaryGradient : null,
          boxShadow: primary && !disabled ? AppTokens.primaryShadow : null,
          border: style == _ButtonStyle.secondary
              ? Border.all(color: AppColors.border)
              : null,
        ),
        alignment: Alignment.center,
        child: loading
            ? NovaLoadingIndicator(
                color: primary ? AppColors.surface : AppColors.primary,
              )
            : NovaText(
                label,
                style: disabled
                    ? labelStyle.copyWith(color: AppColors.disabledText)
                    : labelStyle,
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}

enum NovaIconTone { surface, lavender, hint, mint, error }

class NovaIconButton extends StatelessWidget {
  const NovaIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = NovaIconTone.surface,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final NovaIconTone tone;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final fill = switch (tone) {
      NovaIconTone.surface => AppColors.surface,
      NovaIconTone.lavender => AppColors.pill,
      NovaIconTone.hint => AppColors.hintSurface,
      NovaIconTone.mint => AppColors.successSurface,
      NovaIconTone.error => AppColors.errorSurface,
    };
    return NovaPressable(
      label: label,
      selected: selected ? true : null,
      onPressed: onPressed,
      radius: AppTokens.controlRadius,
      pressScale: AppMotion.iconPressScale,
      child: Container(
        width: AppTokens.iconButtonSize,
        height: AppTokens.iconButtonSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppTokens.controlRadius,
          color: disabled ? AppColors.disabled : fill,
          boxShadow: disabled ? null : AppTokens.iconShadow,
          border: selected ? Border.all(color: AppColors.primary) : null,
        ),
        child: Icon(
          icon,
          size: AppTokens.iconSize,
          color: disabled
              ? AppColors.disabledText
              : tone == NovaIconTone.error
              ? AppColors.error
              : AppColors.primary,
        ),
      ),
    );
  }
}
