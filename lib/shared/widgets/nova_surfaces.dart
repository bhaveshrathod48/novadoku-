import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import 'nova_pressable.dart';

class NovaCard extends StatelessWidget {
  const NovaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    this.elevated = false,
    this.onPressed,
    this.label,
  }) : assert(onPressed == null || label != null);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      constraints: const BoxConstraints(minHeight: AppTokens.cardMinHeight),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTokens.cardRadius,
        boxShadow: elevated ? AppTokens.surfaceShadow : null,
      ),
      child: child,
    );
    if (onPressed == null) return surface;
    return NovaPressable(
      label: label!,
      onPressed: onPressed,
      radius: AppTokens.cardRadius,
      child: surface,
    );
  }
}

enum NovaBadgeTone { surface, lavender, success, error, hint }

class NovaBadge extends StatelessWidget {
  const NovaBadge({
    super.key,
    required this.label,
    this.tone = NovaBadgeTone.lavender,
  });

  final String label;
  final NovaBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      NovaBadgeTone.surface => (AppColors.surface, AppColors.primary),
      NovaBadgeTone.lavender => (AppColors.pill, AppColors.primary),
      NovaBadgeTone.success => (AppColors.successSurface, AppColors.success),
      NovaBadgeTone.error => (AppColors.errorSurface, AppColors.error),
      NovaBadgeTone.hint => (AppColors.hintSurface, AppColors.text),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppTokens.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space6,
        ),
        child: NovaText(
          label,
          style: AppType.badge.copyWith(color: foreground),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
