import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension NovaLocalizations on BuildContext {
  AppLocalizations get strings =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}

/// Reusable components accept authored copy as well as custom caller labels.
/// Flutter's inherited locale rebuilds this text immediately on a language change.
String localize(BuildContext context, String value) {
  final strings = context.strings;
  return switch (value) {
    'Daily challenge, A fresh puzzle every day' =>
      '${strings.dailyChallenge}, ${strings.dailyDescription}',
    "Settings" => strings.settings,
    "Language" => strings.language,
    "System default" => strings.systemDefault,
    "Choose your language." => strings.chooseLanguage,
    "Make it feel like you." => strings.makeItYours,
    "Music" => strings.music,
    "Sound effects" => strings.soundEffects,
    "Haptics" => strings.haptics,
    "Region patterns" => strings.regionPatterns,
    "On" => strings.on,
    "Off" => strings.off,
    "Your preferences, your pace." => strings.preferencesFooter,
    "How to play" => strings.howToPlay,
    "HOW TO PLAY" => strings.howToPlayBadge,
    "Close" => strings.close,
    "Back" => strings.back,
    "Cancel" => strings.cancel,
    "Try again" => strings.tryAgain,
    "Next level" => strings.nextLevel,
    "Back home" => strings.backHome,
    "A little puzzle. A little joy." => strings.tagline,
    "Your next little challenge" => strings.nextChallenge,
    "Daily challenge" => strings.dailyChallenge,
    "A fresh puzzle every day" => strings.dailyDescription,
    "DAILY PLAY" => strings.dailyPlay,
    "A fresh little\nchallenge." => strings.freshChallenge,
    "Today’s puzzle" => strings.todayPuzzle,
    "Same rules. A new arrangement." => strings.newArrangement,
    "Play daily puzzle" => strings.playDaily,
    "One Nova per row, column and region.\nNo touching, even diagonally." =>
      strings.dailyRules,
    "Nova ready to play" => strings.novaReady,
    "Play with Nova" => strings.playWithNova,
    "Small rules.\nBright possibilities." => strings.tutorialTitle,
    "Rows + columns" => strings.rowsColumns,
    "Row + column" => strings.rowColumnBadge,
    "Every region" => strings.everyRegion,
    "Never touch" => strings.neverTouch,
    "Never touching" => strings.neverTouching,
    "One Nova in every\nrow and column." => strings.ruleRows,
    "One Nova in each\ncoloured region." => strings.ruleRegion,
    "Keep Novas apart,\neven diagonally." => strings.ruleTouching,
    "Let’s play" => strings.letsPlay,
    "Gameplay" => strings.gameplay,
    "Find the Novas" => strings.findNovas,
    "Place Nova" => strings.placeNova,
    "Mark X" => strings.markX,
    "Undo" => strings.undo,
    "Reset" => strings.reset,
    "HINT" => strings.hintBadge,
    "A little nudge" => strings.littleNudge,
    "Apply hint" => strings.applyHint,
    "Take a break?" => strings.takeBreak,
    "Your puzzle will be here\nwhen you return." => strings.puzzleHere,
    "Keep playing" => strings.keepPlaying,
    "Save and leave" => strings.saveLeave,
    "One more try?" => strings.oneMoreTry,
    "Beautifully done." => strings.beautifullyDone,
    "A fresh start. A new perspective.\nYou have got this." =>
      strings.freshStart,
    "A FRESH START" => strings.freshStartBadge,
    "PUZZLE COMPLETE" => strings.completeBadge,
    "Your next puzzle is waiting." => strings.nextWaiting,
    "No hint is available." => strings.noHint,
    "Could not load a hint. Try again." => strings.hintLoadError,
    "Could not load the next level. Try again." => strings.nextLoadError,
    "Could not save your puzzle. Try again." => strings.savePuzzleError,
    "Could not load the puzzle." => strings.puzzleLoadError,
    "Could not load today’s puzzle. Try again." => strings.dailyLoadError,
    "Could not load preferences." => strings.preferencesLoadError,
    "Could not save your preference. Try again." =>
      strings.preferencesSaveError,
    "Could not restore campaign progress." => strings.restoreError,
    "Loading" => strings.loading,
    "Loading puzzle" => strings.loadingPuzzle,
    "Loading preferences" => strings.loadingPreferences,
    "Same row. Try another square." => strings.sameRow,
    "Same column. Try another square." => strings.sameColumn,
    "Same region. Try another square." => strings.sameRegion,
    "Novas cannot touch. Try another square." => strings.touchingError,
    "Try another square." => strings.wrongCell,
    "Incorrect placement" => strings.incorrectPlacement,
    "Marked X" => strings.markedX,
    "Empty" => strings.empty,
    "completed" => strings.completed,
    "locked" => strings.locked,
    "unlocked" => strings.unlocked,
    _ => value,
  };
}

class NovaText extends StatelessWidget {
  const NovaText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.semanticsLabel,
    this.maxLines,
    this.overflow,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String? semanticsLabel;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
    localize(context, data),
    style: style,
    textAlign: textAlign,
    semanticsLabel: semanticsLabel == null
        ? null
        : localize(context, semanticsLabel!),
    maxLines: maxLines,
    overflow: overflow,
  );
}
