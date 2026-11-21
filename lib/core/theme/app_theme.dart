import 'package:flutter/material.dart';

import '../typography/app_type.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Nunito Sans',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      secondary: AppColors.primary,
      onSecondary: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.secondaryText,
      error: AppColors.error,
      outline: AppColors.border,
      shadow: AppColors.shadow,
      scrim: AppColors.overlay,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displayLarge: AppType.logo,
      displayMedium: AppType.display,
      headlineMedium: AppType.screenTitle,
      titleLarge: AppType.dialogTitle,
      titleMedium: AppType.sectionTitle,
      bodyLarge: AppType.body,
      bodyMedium: AppType.description,
      labelLarge: AppType.secondaryButton,
      labelMedium: AppType.label,
      labelSmall: AppType.badge,
    ),
    splashFactory: NoSplash.splashFactory,
  );
}
