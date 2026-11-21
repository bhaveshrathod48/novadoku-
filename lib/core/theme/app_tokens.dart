import 'package:flutter/widgets.dart';

import 'app_colors.dart';

abstract final class AppTokens {
  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;
  static const space48 = 48.0;

  static const screenMargin = space24;
  static const compactScreenMargin = space16;
  static const compactBreakpoint = 360.0;
  static const contentMaxWidth = 520.0;
  static const minimumTarget = 48.0;
  static const primaryButtonHeight = 56.0;
  static const secondaryButtonHeight = 52.0;
  static const iconButtonSize = 48.0;
  static const iconSize = 24.0;
  static const smallIconSize = 20.0;
  static const loadingSize = 20.0;
  static const loadingStroke = 2.0;
  static const heartSize = 20.0;
  static const switchWidth = 68.0;
  static const switchHeight = 32.0;
  static const switchThumb = 22.0;
  static const segmentHeight = 50.0;
  static const cardMinHeight = 68.0;
  static const dialogMaxWidth = 408.0;
  static const sheetMaxWidth = 460.0;
  static const hintSheetHeightFraction = 0.68;
  static const modalGutter = space16;
  static const modalPadding = space24;
  static const grabberWidth = 60.0;
  static const grabberHeight = 4.0;
  static const gridGap = space4;
  static const gridPadding = space8;
  static const gridMarkFraction = 0.58;
  static const borderWidth = 1.0;
  static const accentBorderWidth = 2.0;
  static const gridMinHighlightWidth = 1.5;
  static const disabledOpacity = 0.58;
  static const characterHeroWidthFraction = 0.56;
  static const characterAvatarSize = 38.0;
  static const characterHintSize = 72.0;
  static const characterTutorialSize = 88.0;
  static const characterResultSize = 216.0;
  static const settingsRowHeight = 72.0;
  static const dailyCharacterSize = 282.0;
  static const dailyCardWidth = 270.0;
  static const tutorialCardHeight = 102.0;
  static const tutorialCellSize = 16.0;
  static const resultPanelWidth = 256.0;
  static const resultPanelHeight = 226.0;

  static const resultPanelRadius = BorderRadius.all(
    Radius.elliptical(resultPanelWidth / 2, resultPanelHeight / 2),
  );
  static const cellRadius = BorderRadius.all(Radius.circular(9));
  static const controlRadius = BorderRadius.all(Radius.circular(16));
  static const buttonRadius = BorderRadius.all(Radius.circular(19));
  static const cardRadius = BorderRadius.all(Radius.circular(22));
  static const modalRadius = BorderRadius.all(Radius.circular(28));
  static const pillRadius = BorderRadius.all(Radius.circular(100));

  static const surfaceShadow = [
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 5)),
  ];
  static const primaryShadow = [
    BoxShadow(color: AppColors.primaryEdge, offset: Offset(0, 4)),
  ];
  static const iconShadow = [
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 1)),
  ];

  static double screenGutter(double width) =>
      width < compactBreakpoint ? compactScreenMargin : screenMargin;
}
