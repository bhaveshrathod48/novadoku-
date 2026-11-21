// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get chooseLanguage => 'Choose your language.';

  @override
  String get makeItYours => 'Make it feel like you.';

  @override
  String get music => 'Music';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get haptics => 'Haptics';

  @override
  String get regionPatterns => 'Region patterns';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get preferencesFooter => 'Your preferences, your pace.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get howToPlayBadge => 'HOW TO PLAY';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try again';

  @override
  String get nextLevel => 'Next level';

  @override
  String get backHome => 'Back home';

  @override
  String get tagline => 'A little puzzle. A little joy.';

  @override
  String get nextChallenge => 'Your next little challenge';

  @override
  String get dailyChallenge => 'Daily challenge';

  @override
  String get dailyDescription => 'A fresh puzzle every day';

  @override
  String get dailyPlay => 'DAILY PLAY';

  @override
  String get freshChallenge => 'A fresh little\nchallenge.';

  @override
  String get todayPuzzle => 'Today’s puzzle';

  @override
  String get newArrangement => 'Same rules. A new arrangement.';

  @override
  String get playDaily => 'Play daily puzzle';

  @override
  String get dailyRules =>
      'One Nova per row, column and region.\nNo touching, even diagonally.';

  @override
  String get novaReady => 'Nova ready to play';

  @override
  String get playWithNova => 'Play with Nova';

  @override
  String get tutorialTitle => 'Small rules.\nBright possibilities.';

  @override
  String get rowsColumns => 'Rows + columns';

  @override
  String get rowColumnBadge => 'Row + column';

  @override
  String get everyRegion => 'Every region';

  @override
  String get neverTouch => 'Never touch';

  @override
  String get neverTouching => 'Never touching';

  @override
  String get ruleRows => 'One Nova in every\nrow and column.';

  @override
  String get ruleRegion => 'One Nova in each\ncoloured region.';

  @override
  String get ruleTouching => 'Keep Novas apart,\neven diagonally.';

  @override
  String get letsPlay => 'Let’s play';

  @override
  String get gameplay => 'Gameplay';

  @override
  String get findNovas => 'Find the Novas';

  @override
  String get placeNova => 'Place Nova';

  @override
  String get markX => 'Mark X';

  @override
  String get undo => 'Undo';

  @override
  String get reset => 'Reset';

  @override
  String get hintBadge => 'HINT';

  @override
  String get littleNudge => 'A little nudge';

  @override
  String get applyHint => 'Apply hint';

  @override
  String get takeBreak => 'Take a break?';

  @override
  String get puzzleHere => 'Your puzzle will be here\nwhen you return.';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get saveLeave => 'Save and leave';

  @override
  String get oneMoreTry => 'One more try?';

  @override
  String get beautifullyDone => 'Beautifully done.';

  @override
  String get freshStart =>
      'A fresh start. A new perspective.\nYou have got this.';

  @override
  String get freshStartBadge => 'A FRESH START';

  @override
  String get completeBadge => 'PUZZLE COMPLETE';

  @override
  String get nextWaiting => 'Your next puzzle is waiting.';

  @override
  String get noHint => 'No hint is available.';

  @override
  String get hintLoadError => 'Could not load a hint. Try again.';

  @override
  String get nextLoadError => 'Could not load the next level. Try again.';

  @override
  String get savePuzzleError => 'Could not save your puzzle. Try again.';

  @override
  String get puzzleLoadError => 'Could not load the puzzle.';

  @override
  String get dailyLoadError => 'Could not load today’s puzzle. Try again.';

  @override
  String get preferencesLoadError => 'Could not load preferences.';

  @override
  String get preferencesSaveError =>
      'Could not save your preference. Try again.';

  @override
  String get restoreError => 'Could not restore campaign progress.';

  @override
  String get loading => 'Loading';

  @override
  String get loadingPuzzle => 'Loading puzzle';

  @override
  String get loadingPreferences => 'Loading preferences';

  @override
  String get sameRow => 'Same row. Try another square.';

  @override
  String get sameColumn => 'Same column. Try another square.';

  @override
  String get sameRegion => 'Same region. Try another square.';

  @override
  String get touchingError => 'Novas cannot touch. Try another square.';

  @override
  String get wrongCell => 'Try another square.';

  @override
  String get incorrectPlacement => 'Incorrect placement';

  @override
  String get markedX => 'Marked X';

  @override
  String get empty => 'Empty';

  @override
  String get completed => 'completed';

  @override
  String get locked => 'locked';

  @override
  String get unlocked => 'unlocked';

  @override
  String level(int number) {
    return 'Level $number';
  }

  @override
  String levelBadge(int number) {
    return 'LEVEL $number';
  }

  @override
  String playLevel(int number) {
    return 'Play level $number';
  }

  @override
  String levelLoadError(int number) {
    return 'Could not load level $number. Try again.';
  }

  @override
  String foundCount(int placed, int total) {
    return '$placed of $total';
  }

  @override
  String hintCount(int count) {
    return 'Hint · $count';
  }

  @override
  String levelStatus(String level, String status) {
    return '$level, $status';
  }

  @override
  String languageLabel(String label, String language) {
    return '$label, $language';
  }

  @override
  String busyLabel(String label) {
    return '$label, Loading';
  }

  @override
  String cellDescription(int row, int column, int region, String state) {
    return 'Row $row, column $column, region $region. $state.';
  }

  @override
  String hintCellDescription(String cell) {
    return 'Hint. $cell';
  }

  @override
  String unitRow(int number) {
    return 'row $number';
  }

  @override
  String unitColumn(int number) {
    return 'column $number';
  }

  @override
  String unitRegion(int number) {
    return 'region $number';
  }

  @override
  String hintRow(int row) {
    return 'Row $row already has a Nova.';
  }

  @override
  String hintColumn(int column) {
    return 'Column $column already has a Nova.';
  }

  @override
  String hintRegion(int region) {
    return 'Region $region already has a Nova.';
  }

  @override
  String get hintTouching => 'A Nova here would touch a placed Nova.';

  @override
  String hintActionX(int row, int column) {
    return 'Mark row $row, column $column with an X.';
  }

  @override
  String hintSingle(int row, int column, String unit) {
    return 'Row $row, column $column is the only possible Nova in $unit. Place a Nova there.';
  }

  @override
  String hintLocked(int row, int column, String unit) {
    return 'A Nova at row $row, column $column would rule out every possible Nova in $unit.';
  }

  @override
  String hintContradiction(int row, int column, String unit) {
    return 'A Nova at row $row, column $column would force moves that leave $unit without a Nova.';
  }

  @override
  String hintSearch(int row, int column) {
    return 'Assuming a Nova at row $row, column $column leaves no way to satisfy all rows, columns, regions, and the no-touch rule.';
  }

  @override
  String attemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts left',
      one: '1 attempt left',
      zero: '0 attempts left',
    );
    return '$_temp0';
  }

  @override
  String hintsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hint, $count remaining',
      one: 'Hint, 1 remaining',
      zero: 'Hint, 0 remaining',
    );
    return '$_temp0';
  }

  @override
  String allFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count Novas found.',
      one: 'All 1 Nova found.',
    );
    return '$_temp0';
  }

  @override
  String get hint => 'Hint';

  @override
  String get restartPuzzle => 'Restart this puzzle?';

  @override
  String get restartDescription =>
      'Your marks will be cleared. Attempts and power-ups will be restored.';

  @override
  String novaUsesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nova reveals left',
      one: '1 Nova reveal left',
      zero: 'No Nova reveals left',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profile';

  @override
  String get profileUsername => 'Username';

  @override
  String get profileAvatars => 'Avatar';

  @override
  String get profileFrames => 'Frame';

  @override
  String get profileConfirm => 'Confirm';

  @override
  String get profileNameError => 'Enter a name of 1–32 characters.';

  @override
  String get profileSaveError =>
      'Could not save your profile. Please try again.';

  @override
  String get profileLoadError =>
      'Could not load your profile. Please try again.';

  @override
  String get avatarPanda => 'Panda';

  @override
  String get avatarFox => 'Fox';

  @override
  String get avatarBunny => 'Bunny';

  @override
  String get avatarLion => 'Lion';

  @override
  String get avatarKoala => 'Koala';

  @override
  String get avatarPenguin => 'Penguin';

  @override
  String get avatarBear => 'Bear';

  @override
  String get frameClassicPurple => 'Classic Purple';

  @override
  String get frameRoyalGold => 'Royal Gold';

  @override
  String get frameRose => 'Rose';

  @override
  String get frameMint => 'Mint';

  @override
  String get frameCosmic => 'Cosmic';

  @override
  String get frameFrost => 'Frost';

  @override
  String get frameSunshine => 'Sunshine';

  @override
  String get frameRainbow => 'Rainbow';
}
