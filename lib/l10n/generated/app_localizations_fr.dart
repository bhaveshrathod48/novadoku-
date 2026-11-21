// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Réglages';

  @override
  String get language => 'Langue';

  @override
  String get systemDefault => 'Langue du système';

  @override
  String get chooseLanguage => 'Choisissez votre langue.';

  @override
  String get makeItYours => 'Jouez à votre façon.';

  @override
  String get music => 'Musique';

  @override
  String get soundEffects => 'Effets sonores';

  @override
  String get haptics => 'Vibrations';

  @override
  String get regionPatterns => 'Motifs des régions';

  @override
  String get on => 'Oui';

  @override
  String get off => 'Non';

  @override
  String get preferencesFooter => 'Vos envies, votre rythme.';

  @override
  String get howToPlay => 'Comment jouer';

  @override
  String get howToPlayBadge => 'COMMENT JOUER';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get cancel => 'Annuler';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get nextLevel => 'Niveau suivant';

  @override
  String get backHome => 'Accueil';

  @override
  String get tagline => 'Un petit puzzle. Un peu de bonheur.';

  @override
  String get nextChallenge => 'Votre prochain petit défi';

  @override
  String get dailyChallenge => 'Défi du jour';

  @override
  String get dailyDescription => 'Un nouveau puzzle chaque jour';

  @override
  String get dailyPlay => 'DÉFI DU JOUR';

  @override
  String get freshChallenge => 'Un nouveau\npetit défi.';

  @override
  String get todayPuzzle => 'Le puzzle du jour';

  @override
  String get newArrangement => 'Mêmes règles. Nouvelle disposition.';

  @override
  String get playDaily => 'Jouer au puzzle du jour';

  @override
  String get dailyRules =>
      'Un Nova par ligne, colonne et région.\nIls ne se touchent pas, même en diagonale.';

  @override
  String get novaReady => 'Nova est prêt à jouer';

  @override
  String get playWithNova => 'Jouer avec Nova';

  @override
  String get tutorialTitle => 'Petites règles.\nGrandes possibilités.';

  @override
  String get rowsColumns => 'Lignes + colonnes';

  @override
  String get rowColumnBadge => 'Ligne + colonne';

  @override
  String get everyRegion => 'Chaque région';

  @override
  String get neverTouch => 'Sans contact';

  @override
  String get neverTouching => 'Ne jamais se toucher';

  @override
  String get ruleRows => 'Un Nova dans chaque\nligne et colonne.';

  @override
  String get ruleRegion => 'Un Nova dans chaque\nrégion colorée.';

  @override
  String get ruleTouching => 'Séparez les Nova,\nmême en diagonale.';

  @override
  String get letsPlay => 'C’est parti';

  @override
  String get gameplay => 'Partie';

  @override
  String get findNovas => 'Trouvez les Nova';

  @override
  String get placeNova => 'Placer Nova';

  @override
  String get markX => 'Marquer X';

  @override
  String get undo => 'Annuler le coup';

  @override
  String get reset => 'Recommencer';

  @override
  String get hintBadge => 'INDICE';

  @override
  String get littleNudge => 'Un petit coup de pouce';

  @override
  String get applyHint => 'Appliquer l’indice';

  @override
  String get takeBreak => 'Faire une pause ?';

  @override
  String get puzzleHere => 'Votre puzzle vous attendra\nà votre retour.';

  @override
  String get keepPlaying => 'Continuer';

  @override
  String get saveLeave => 'Enregistrer et quitter';

  @override
  String get oneMoreTry => 'Encore un essai ?';

  @override
  String get beautifullyDone => 'Bien joué.';

  @override
  String get freshStart =>
      'Un nouveau départ. Un regard neuf.\nVous allez y arriver.';

  @override
  String get freshStartBadge => 'UN NOUVEAU DÉPART';

  @override
  String get completeBadge => 'PUZZLE TERMINÉ';

  @override
  String get nextWaiting => 'Votre prochain puzzle vous attend.';

  @override
  String get noHint => 'Aucun indice disponible.';

  @override
  String get hintLoadError => 'Impossible de charger l’indice. Réessayez.';

  @override
  String get nextLoadError =>
      'Impossible de charger le niveau suivant. Réessayez.';

  @override
  String get savePuzzleError =>
      'Impossible d’enregistrer votre puzzle. Réessayez.';

  @override
  String get puzzleLoadError => 'Impossible de charger le puzzle.';

  @override
  String get dailyLoadError =>
      'Impossible de charger le puzzle du jour. Réessayez.';

  @override
  String get preferencesLoadError => 'Impossible de charger les préférences.';

  @override
  String get preferencesSaveError =>
      'Impossible d’enregistrer votre préférence. Réessayez.';

  @override
  String get restoreError => 'Impossible de restaurer votre progression.';

  @override
  String get loading => 'Chargement';

  @override
  String get loadingPuzzle => 'Chargement du puzzle';

  @override
  String get loadingPreferences => 'Chargement des préférences';

  @override
  String get sameRow => 'Même ligne. Essayez une autre case.';

  @override
  String get sameColumn => 'Même colonne. Essayez une autre case.';

  @override
  String get sameRegion => 'Même région. Essayez une autre case.';

  @override
  String get touchingError =>
      'Les Nova ne doivent pas se toucher. Essayez une autre case.';

  @override
  String get wrongCell => 'Essayez une autre case.';

  @override
  String get incorrectPlacement => 'Placement incorrect';

  @override
  String get markedX => 'Marquée X';

  @override
  String get empty => 'Vide';

  @override
  String get completed => 'terminé';

  @override
  String get locked => 'verrouillé';

  @override
  String get unlocked => 'déverrouillé';

  @override
  String level(int number) {
    return 'Niveau $number';
  }

  @override
  String levelBadge(int number) {
    return 'NIVEAU $number';
  }

  @override
  String playLevel(int number) {
    return 'Jouer au niveau $number';
  }

  @override
  String levelLoadError(int number) {
    return 'Impossible de charger le niveau $number. Réessayez.';
  }

  @override
  String foundCount(int placed, int total) {
    return '$placed sur $total';
  }

  @override
  String hintCount(int count) {
    return 'Indice · $count';
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
    return '$label, chargement';
  }

  @override
  String cellDescription(int row, int column, int region, String state) {
    return 'Ligne $row, colonne $column, région $region. $state.';
  }

  @override
  String hintCellDescription(String cell) {
    return 'Indice. $cell';
  }

  @override
  String unitRow(int number) {
    return 'la ligne $number';
  }

  @override
  String unitColumn(int number) {
    return 'la colonne $number';
  }

  @override
  String unitRegion(int number) {
    return 'la région $number';
  }

  @override
  String hintRow(int row) {
    return 'La ligne $row contient déjà un Nova.';
  }

  @override
  String hintColumn(int column) {
    return 'La colonne $column contient déjà un Nova.';
  }

  @override
  String hintRegion(int region) {
    return 'La région $region contient déjà un Nova.';
  }

  @override
  String get hintTouching => 'Un Nova ici toucherait un Nova déjà placé.';

  @override
  String hintActionX(int row, int column) {
    return 'Marquez d’un X la case à la ligne $row, colonne $column.';
  }

  @override
  String hintSingle(int row, int column, String unit) {
    return 'La case à la ligne $row, colonne $column est le seul emplacement possible pour un Nova dans $unit. Placez-y un Nova.';
  }

  @override
  String hintLocked(int row, int column, String unit) {
    return 'Un Nova à la ligne $row, colonne $column supprimerait toutes les possibilités dans $unit.';
  }

  @override
  String hintContradiction(int row, int column, String unit) {
    return 'Un Nova à la ligne $row, colonne $column imposerait des coups laissant $unit sans Nova.';
  }

  @override
  String hintSearch(int row, int column) {
    return 'Placer un Nova à la ligne $row, colonne $column empêcherait de respecter toutes les lignes, colonnes, régions et la règle de non-contact.';
  }

  @override
  String attemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count essais restants',
      one: '1 essai restant',
      zero: '0 essai restant',
    );
    return '$_temp0';
  }

  @override
  String hintsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Indices, $count restants',
      one: 'Indice, 1 restant',
      zero: 'Indice, 0 restant',
    );
    return '$_temp0';
  }

  @override
  String allFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count Nova ont été trouvés.',
      one: 'Le Nova a été trouvé.',
    );
    return '$_temp0';
  }

  @override
  String get hint => 'Indice';

  @override
  String get restartPuzzle => 'Recommencer ce puzzle ?';

  @override
  String get restartDescription =>
      'Vos marques seront effacées. Vos essais et vos bonus seront réinitialisés.';

  @override
  String novaUsesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count révélations de Nova restantes',
      one: '1 révélation de Nova restante',
      zero: 'Aucune révélation de Nova restante',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profil';

  @override
  String get profileUsername => 'Nom d’utilisateur';

  @override
  String get profileAvatars => 'Avatar';

  @override
  String get profileFrames => 'Cadre';

  @override
  String get profileConfirm => 'Confirmer';

  @override
  String get profileNameError => 'Saisissez un nom de 1 à 32 caractères.';

  @override
  String get profileSaveError =>
      'Impossible d’enregistrer le profil. Réessayez.';

  @override
  String get profileLoadError => 'Impossible de charger le profil. Réessayez.';

  @override
  String get avatarPanda => 'Panda';

  @override
  String get avatarFox => 'Renard';

  @override
  String get avatarBunny => 'Lapin';

  @override
  String get avatarLion => 'Lion';

  @override
  String get avatarKoala => 'Koala';

  @override
  String get avatarPenguin => 'Manchot';

  @override
  String get avatarBear => 'Ours';

  @override
  String get frameClassicPurple => 'Violet classique';

  @override
  String get frameRoyalGold => 'Or royal';

  @override
  String get frameRose => 'Rose';

  @override
  String get frameMint => 'Menthe';

  @override
  String get frameCosmic => 'Cosmique';

  @override
  String get frameFrost => 'Givre';

  @override
  String get frameSunshine => 'Soleil';

  @override
  String get frameRainbow => 'Arc-en-ciel';
}
