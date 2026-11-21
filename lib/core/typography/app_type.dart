import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppType {
  static const _heading = TextStyle(
    fontFamily: 'DynaPuff',
    fontFamilyFallback: ['Noto Sans', 'Noto Sans Devanagari', 'Noto Sans JP'],
    color: AppColors.text,
  );
  static const _text = TextStyle(
    fontFamily: 'Nunito Sans',
    fontFamilyFallback: ['Noto Sans', 'Noto Sans Devanagari', 'Noto Sans JP'],
    color: AppColors.text,
  );

  // Home's original wordmark is drawn artwork, independent of these styles.
  static final logo = _display(54, 1.12, weight: 700, letterSpacing: -1.5);
  static final display = _display(38, 1.12, weight: 700, letterSpacing: -0.4);
  static final screenTitle = _display(30, 1.16);
  static final tutorialTitle = _display(32, 1.16, weight: 700);
  static final dialogTitle = _display(30, 1.16);
  static final sectionTitle = _support(16, 700);
  static final primaryButton = _support(16, 700, color: AppColors.surface);
  static final secondaryButton = _support(16, 700);
  static final body = _support(16, 600);
  static final settingLabel = _support(16, 700);
  static final description = _support(14, 600, color: AppColors.secondaryText);
  static final label = _support(12, 700, color: AppColors.secondaryText);
  static final gridNumber = _support(10, 700);
  static final badge = _support(11, 700, color: AppColors.primary);
  static final eyebrow = badge.copyWith(letterSpacing: 1.8);
  static final error = _support(12, 700, color: AppColors.error);

  static TextStyle _display(
    double size,
    double height, {
    double weight = 600,
    double? letterSpacing,
  }) => _heading.copyWith(
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    fontWeight: weight == 700 ? FontWeight.w700 : FontWeight.w600,
    fontVariations: [FontVariation('wdth', 95), FontVariation.weight(weight)],
  );

  static TextStyle _support(double size, double weight, {Color? color}) =>
      _text.copyWith(
        fontSize: size,
        height: 1.3,
        color: color,
        fontWeight: weight == 700 ? FontWeight.w700 : FontWeight.w600,
        fontVariations: [FontVariation.weight(weight)],
      );
}
