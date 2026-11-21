import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const pressDuration = Duration(milliseconds: 110);
  static const pressRelease = Duration(milliseconds: 175);
  static const controlDuration = Duration(milliseconds: 160);
  static const fadeDuration = Duration(milliseconds: 180);
  static const scaleDuration = Duration(milliseconds: 220);
  static const dialogEnter = Duration(milliseconds: 240);
  static const dialogExit = Duration(milliseconds: 180);
  static const sheetEnter = Duration(milliseconds: 300);
  static const sheetExit = Duration(milliseconds: 220);
  static const cellPop = Duration(milliseconds: 235);
  static const cellShake = Duration(milliseconds: 270);
  static const heartLoss = Duration(milliseconds: 340);
  static const hintHighlight = Duration(milliseconds: 740);
  static const celebration = Duration(milliseconds: 1550);
  static const screenEnter = Duration(milliseconds: 260);
  static const screenExit = Duration(milliseconds: 200);
  static const brandArrival = Duration(milliseconds: 420);
  static const tutorialDemonstration = Duration(milliseconds: 1800);
  static const backgroundSettle = Duration(milliseconds: 2000);
  static const routeStartOffset = Offset(0, 0.025);

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const pressCurve = Curves.easeOut;
  static const springCurve = Curves.easeOutBack;
  static const spring = SpringDescription(mass: 1, stiffness: 350, damping: 24);
  static const pressScale = 0.97;
  static const buttonPressScale = 0.985;
  static const iconPressScale = 0.94;
  static const buttonPressOffset = Offset(0, .025);
  static const dialogStartScale = 0.96;
  static const popStartScale = 0.78;
  static const sheetStartOffset = Offset(0, 1);

  static Duration durationOf(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
