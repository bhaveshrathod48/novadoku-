import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language.'**
  String get chooseLanguage;

  /// No description provided for @makeItYours.
  ///
  /// In en, this message translates to:
  /// **'Make it feel like you.'**
  String get makeItYours;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @regionPatterns.
  ///
  /// In en, this message translates to:
  /// **'Region patterns'**
  String get regionPatterns;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @preferencesFooter.
  ///
  /// In en, this message translates to:
  /// **'Your preferences, your pace.'**
  String get preferencesFooter;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @howToPlayBadge.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlayBadge;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back home'**
  String get backHome;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'A little puzzle. A little joy.'**
  String get tagline;

  /// No description provided for @nextChallenge.
  ///
  /// In en, this message translates to:
  /// **'Your next little challenge'**
  String get nextChallenge;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyDescription.
  ///
  /// In en, this message translates to:
  /// **'A fresh puzzle every day'**
  String get dailyDescription;

  /// No description provided for @dailyPlay.
  ///
  /// In en, this message translates to:
  /// **'DAILY PLAY'**
  String get dailyPlay;

  /// No description provided for @freshChallenge.
  ///
  /// In en, this message translates to:
  /// **'A fresh little\nchallenge.'**
  String get freshChallenge;

  /// No description provided for @todayPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Today’s puzzle'**
  String get todayPuzzle;

  /// No description provided for @newArrangement.
  ///
  /// In en, this message translates to:
  /// **'Same rules. A new arrangement.'**
  String get newArrangement;

  /// No description provided for @playDaily.
  ///
  /// In en, this message translates to:
  /// **'Play daily puzzle'**
  String get playDaily;

  /// No description provided for @dailyRules.
  ///
  /// In en, this message translates to:
  /// **'One Nova per row, column and region.\nNo touching, even diagonally.'**
  String get dailyRules;

  /// No description provided for @novaReady.
  ///
  /// In en, this message translates to:
  /// **'Nova ready to play'**
  String get novaReady;

  /// No description provided for @playWithNova.
  ///
  /// In en, this message translates to:
  /// **'Play with Nova'**
  String get playWithNova;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Small rules.\nBright possibilities.'**
  String get tutorialTitle;

  /// No description provided for @rowsColumns.
  ///
  /// In en, this message translates to:
  /// **'Rows + columns'**
  String get rowsColumns;

  /// No description provided for @rowColumnBadge.
  ///
  /// In en, this message translates to:
  /// **'Row + column'**
  String get rowColumnBadge;

  /// No description provided for @everyRegion.
  ///
  /// In en, this message translates to:
  /// **'Every region'**
  String get everyRegion;

  /// No description provided for @neverTouch.
  ///
  /// In en, this message translates to:
  /// **'Never touch'**
  String get neverTouch;

  /// No description provided for @neverTouching.
  ///
  /// In en, this message translates to:
  /// **'Never touching'**
  String get neverTouching;

  /// No description provided for @ruleRows.
  ///
  /// In en, this message translates to:
  /// **'One Nova in every\nrow and column.'**
  String get ruleRows;

  /// No description provided for @ruleRegion.
  ///
  /// In en, this message translates to:
  /// **'One Nova in each\ncoloured region.'**
  String get ruleRegion;

  /// No description provided for @ruleTouching.
  ///
  /// In en, this message translates to:
  /// **'Keep Novas apart,\neven diagonally.'**
  String get ruleTouching;

  /// No description provided for @letsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let’s play'**
  String get letsPlay;

  /// No description provided for @gameplay.
  ///
  /// In en, this message translates to:
  /// **'Gameplay'**
  String get gameplay;

  /// No description provided for @findNovas.
  ///
  /// In en, this message translates to:
  /// **'Find the Novas'**
  String get findNovas;

  /// No description provided for @placeNova.
  ///
  /// In en, this message translates to:
  /// **'Place Nova'**
  String get placeNova;

  /// No description provided for @markX.
  ///
  /// In en, this message translates to:
  /// **'Mark X'**
  String get markX;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @hintBadge.
  ///
  /// In en, this message translates to:
  /// **'HINT'**
  String get hintBadge;

  /// No description provided for @littleNudge.
  ///
  /// In en, this message translates to:
  /// **'A little nudge'**
  String get littleNudge;

  /// No description provided for @applyHint.
  ///
  /// In en, this message translates to:
  /// **'Apply hint'**
  String get applyHint;

  /// No description provided for @takeBreak.
  ///
  /// In en, this message translates to:
  /// **'Take a break?'**
  String get takeBreak;

  /// No description provided for @puzzleHere.
  ///
  /// In en, this message translates to:
  /// **'Your puzzle will be here\nwhen you return.'**
  String get puzzleHere;

  /// No description provided for @keepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get keepPlaying;

  /// No description provided for @saveLeave.
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get saveLeave;

  /// No description provided for @oneMoreTry.
  ///
  /// In en, this message translates to:
  /// **'One more try?'**
  String get oneMoreTry;

  /// No description provided for @beautifullyDone.
  ///
  /// In en, this message translates to:
  /// **'Beautifully done.'**
  String get beautifullyDone;

  /// No description provided for @freshStart.
  ///
  /// In en, this message translates to:
  /// **'A fresh start. A new perspective.\nYou have got this.'**
  String get freshStart;

  /// No description provided for @freshStartBadge.
  ///
  /// In en, this message translates to:
  /// **'A FRESH START'**
  String get freshStartBadge;

  /// No description provided for @completeBadge.
  ///
  /// In en, this message translates to:
  /// **'PUZZLE COMPLETE'**
  String get completeBadge;

  /// No description provided for @nextWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your next puzzle is waiting.'**
  String get nextWaiting;

  /// No description provided for @noHint.
  ///
  /// In en, this message translates to:
  /// **'No hint is available.'**
  String get noHint;

  /// No description provided for @hintLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load a hint. Try again.'**
  String get hintLoadError;

  /// No description provided for @nextLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the next level. Try again.'**
  String get nextLoadError;

  /// No description provided for @savePuzzleError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your puzzle. Try again.'**
  String get savePuzzleError;

  /// No description provided for @puzzleLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the puzzle.'**
  String get puzzleLoadError;

  /// No description provided for @dailyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load today’s puzzle. Try again.'**
  String get dailyLoadError;

  /// No description provided for @preferencesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load preferences.'**
  String get preferencesLoadError;

  /// No description provided for @preferencesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your preference. Try again.'**
  String get preferencesSaveError;

  /// No description provided for @restoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not restore campaign progress.'**
  String get restoreError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @loadingPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Loading puzzle'**
  String get loadingPuzzle;

  /// No description provided for @loadingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Loading preferences'**
  String get loadingPreferences;

  /// No description provided for @sameRow.
  ///
  /// In en, this message translates to:
  /// **'Same row. Try another square.'**
  String get sameRow;

  /// No description provided for @sameColumn.
  ///
  /// In en, this message translates to:
  /// **'Same column. Try another square.'**
  String get sameColumn;

  /// No description provided for @sameRegion.
  ///
  /// In en, this message translates to:
  /// **'Same region. Try another square.'**
  String get sameRegion;

  /// No description provided for @touchingError.
  ///
  /// In en, this message translates to:
  /// **'Novas cannot touch. Try another square.'**
  String get touchingError;

  /// No description provided for @wrongCell.
  ///
  /// In en, this message translates to:
  /// **'Try another square.'**
  String get wrongCell;

  /// No description provided for @incorrectPlacement.
  ///
  /// In en, this message translates to:
  /// **'Incorrect placement'**
  String get incorrectPlacement;

  /// No description provided for @markedX.
  ///
  /// In en, this message translates to:
  /// **'Marked X'**
  String get markedX;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get unlocked;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String level(int number);

  /// No description provided for @levelBadge.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {number}'**
  String levelBadge(int number);

  /// No description provided for @playLevel.
  ///
  /// In en, this message translates to:
  /// **'Play level {number}'**
  String playLevel(int number);

  /// No description provided for @levelLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load level {number}. Try again.'**
  String levelLoadError(int number);

  /// No description provided for @foundCount.
  ///
  /// In en, this message translates to:
  /// **'{placed} of {total}'**
  String foundCount(int placed, int total);

  /// No description provided for @hintCount.
  ///
  /// In en, this message translates to:
  /// **'Hint · {count}'**
  String hintCount(int count);

  /// No description provided for @levelStatus.
  ///
  /// In en, this message translates to:
  /// **'{level}, {status}'**
  String levelStatus(String level, String status);

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}, {language}'**
  String languageLabel(String label, String language);

  /// No description provided for @busyLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}, Loading'**
  String busyLabel(String label);

  /// No description provided for @cellDescription.
  ///
  /// In en, this message translates to:
  /// **'Row {row}, column {column}, region {region}. {state}.'**
  String cellDescription(int row, int column, int region, String state);

  /// No description provided for @hintCellDescription.
  ///
  /// In en, this message translates to:
  /// **'Hint. {cell}'**
  String hintCellDescription(String cell);

  /// No description provided for @unitRow.
  ///
  /// In en, this message translates to:
  /// **'row {number}'**
  String unitRow(int number);

  /// No description provided for @unitColumn.
  ///
  /// In en, this message translates to:
  /// **'column {number}'**
  String unitColumn(int number);

  /// No description provided for @unitRegion.
  ///
  /// In en, this message translates to:
  /// **'region {number}'**
  String unitRegion(int number);

  /// No description provided for @hintRow.
  ///
  /// In en, this message translates to:
  /// **'Row {row} already has a Nova.'**
  String hintRow(int row);

  /// No description provided for @hintColumn.
  ///
  /// In en, this message translates to:
  /// **'Column {column} already has a Nova.'**
  String hintColumn(int column);

  /// No description provided for @hintRegion.
  ///
  /// In en, this message translates to:
  /// **'Region {region} already has a Nova.'**
  String hintRegion(int region);

  /// No description provided for @hintTouching.
  ///
  /// In en, this message translates to:
  /// **'A Nova here would touch a placed Nova.'**
  String get hintTouching;

  /// No description provided for @hintActionX.
  ///
  /// In en, this message translates to:
  /// **'Mark row {row}, column {column} with an X.'**
  String hintActionX(int row, int column);

  /// No description provided for @hintSingle.
  ///
  /// In en, this message translates to:
  /// **'Row {row}, column {column} is the only possible Nova in {unit}. Place a Nova there.'**
  String hintSingle(int row, int column, String unit);

  /// No description provided for @hintLocked.
  ///
  /// In en, this message translates to:
  /// **'A Nova at row {row}, column {column} would rule out every possible Nova in {unit}.'**
  String hintLocked(int row, int column, String unit);

  /// No description provided for @hintContradiction.
  ///
  /// In en, this message translates to:
  /// **'A Nova at row {row}, column {column} would force moves that leave {unit} without a Nova.'**
  String hintContradiction(int row, int column, String unit);

  /// No description provided for @hintSearch.
  ///
  /// In en, this message translates to:
  /// **'Assuming a Nova at row {row}, column {column} leaves no way to satisfy all rows, columns, regions, and the no-touch rule.'**
  String hintSearch(int row, int column);

  /// No description provided for @attemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 attempts left} one{1 attempt left} other{{count} attempts left}}'**
  String attemptsLeft(int count);

  /// No description provided for @hintsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Hint, 0 remaining} one{Hint, 1 remaining} other{Hint, {count} remaining}}'**
  String hintsRemaining(int count);

  /// No description provided for @allFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{All 1 Nova found.} other{All {count} Novas found.}}'**
  String allFound(int count);

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @restartPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Restart this puzzle?'**
  String get restartPuzzle;

  /// No description provided for @restartDescription.
  ///
  /// In en, this message translates to:
  /// **'Your marks will be cleared. Attempts and power-ups will be restored.'**
  String get restartDescription;

  /// No description provided for @novaUsesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No Nova reveals left} =1{1 Nova reveal left} other{{count} Nova reveals left}}'**
  String novaUsesRemaining(int count);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// No description provided for @profileAvatars.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get profileAvatars;

  /// No description provided for @profileFrames.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get profileFrames;

  /// No description provided for @profileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get profileConfirm;

  /// No description provided for @profileNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of 1–32 characters.'**
  String get profileNameError;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get profileSaveError;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get profileLoadError;

  /// No description provided for @avatarPanda.
  ///
  /// In en, this message translates to:
  /// **'Panda'**
  String get avatarPanda;

  /// No description provided for @avatarFox.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get avatarFox;

  /// No description provided for @avatarBunny.
  ///
  /// In en, this message translates to:
  /// **'Bunny'**
  String get avatarBunny;

  /// No description provided for @avatarLion.
  ///
  /// In en, this message translates to:
  /// **'Lion'**
  String get avatarLion;

  /// No description provided for @avatarKoala.
  ///
  /// In en, this message translates to:
  /// **'Koala'**
  String get avatarKoala;

  /// No description provided for @avatarPenguin.
  ///
  /// In en, this message translates to:
  /// **'Penguin'**
  String get avatarPenguin;

  /// No description provided for @avatarBear.
  ///
  /// In en, this message translates to:
  /// **'Bear'**
  String get avatarBear;

  /// No description provided for @frameClassicPurple.
  ///
  /// In en, this message translates to:
  /// **'Classic Purple'**
  String get frameClassicPurple;

  /// No description provided for @frameRoyalGold.
  ///
  /// In en, this message translates to:
  /// **'Royal Gold'**
  String get frameRoyalGold;

  /// No description provided for @frameRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get frameRose;

  /// No description provided for @frameMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get frameMint;

  /// No description provided for @frameCosmic.
  ///
  /// In en, this message translates to:
  /// **'Cosmic'**
  String get frameCosmic;

  /// No description provided for @frameFrost.
  ///
  /// In en, this message translates to:
  /// **'Frost'**
  String get frameFrost;

  /// No description provided for @frameSunshine.
  ///
  /// In en, this message translates to:
  /// **'Sunshine'**
  String get frameSunshine;

  /// No description provided for @frameRainbow.
  ///
  /// In en, this message translates to:
  /// **'Rainbow'**
  String get frameRainbow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fr',
    'hi',
    'ja',
    'pt',
    'ru',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
