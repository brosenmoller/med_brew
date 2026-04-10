// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Med Brew';

  @override
  String get settingsTooltip => 'Instellingen';

  @override
  String get navBrowse => 'Bladeren';

  @override
  String get navBrowseSubtitle => 'Verken quizzen & categorieën';

  @override
  String get navSpacedRepetition => 'Spaced Repetition';

  @override
  String get navSpacedRepetitionSubtitle => 'Bekijk je te herhalen kaarten';

  @override
  String get navFavorites => 'Favorieten';

  @override
  String get navFavoritesSubtitle => 'Je opgeslagen quizzen';

  @override
  String get navManageContent => 'Inhoud beheren';

  @override
  String get navManageContentSubtitle => 'Vragen aanmaken en bewerken';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsResetSrs => 'Alle SRS-gegevens resetten';

  @override
  String get settingsResetSrsDialogTitle => 'SRS-gegevens resetten';

  @override
  String get settingsResetSrsDialogContent =>
      'Weet je zeker dat je alle SRS-gegevens wilt resetten? Dit kan niet ongedaan worden gemaakt.';

  @override
  String get settingsResetSrsSuccess => 'Alle SRS-gegevens gereset';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageSystem => 'Systeemstandaard';

  @override
  String get settingsLanguageEnglish => 'Engels';

  @override
  String get settingsLanguageDutch => 'Nederlands';

  @override
  String get cancel => 'Annuleren';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get delete => 'Verwijderen';

  @override
  String get save => 'Opslaan';

  @override
  String get reset => 'Resetten';

  @override
  String get edit => 'Bewerken';

  @override
  String get required => 'Verplicht';

  @override
  String get start => 'Starten';

  @override
  String get retry => 'Opnieuw';

  @override
  String get back => 'Terug';

  @override
  String get home => 'Home';

  @override
  String get remove => 'Verwijderen';

  @override
  String get saveChanges => 'Wijzigingen opslaan';

  @override
  String get foldersSection => 'Mappen';

  @override
  String get quizzesSection => 'Quizzen';

  @override
  String get emptyFolder => 'Hier is nog niets.';

  @override
  String get favoritesTitle => 'Favorieten';

  @override
  String get favoritesEmpty => 'Nog geen favoriete quizzen.';

  @override
  String get srsTitle => 'Spaced Repetition';

  @override
  String get srsNoQuestions => 'Geen spaced repetition-vragen beschikbaar';

  @override
  String srsDue(int count) {
    return '$count te herhalen';
  }

  @override
  String srsCards(int count) {
    return '$count kaarten';
  }

  @override
  String srsOldestOverdue(String time) {
    return 'oudste $time verlopen';
  }

  @override
  String srsNextIn(String time) {
    return 'volgende in $time';
  }

  @override
  String get srsStartNormalQuiz => 'Normale quiz starten';

  @override
  String get srsNoSrsScheduling => 'Geen SRS-planning';

  @override
  String get srsRemoveFromSrs => 'Uit SRS verwijderen';

  @override
  String get srsRemoveDialogTitle => 'Uit spaced repetition verwijderen?';

  @override
  String srsRemoveDialogContent(String quizTitle) {
    return 'Alle SRS-voortgang voor \"$quizTitle\" gaat verloren. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get srsNoQuestionsDue => 'Geen vragen te herhalen';

  @override
  String get srsSessionComplete => 'Sessie voltooid';

  @override
  String srsQuestionsReviewed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vragen herhaald',
      one: '1 vraag herhaald',
    );
    return '$_temp0';
  }

  @override
  String get srsAllCaughtUp => 'Alles bijgewerkt!';

  @override
  String get srsNoMoreDue => 'Geen vragen meer te herhalen.';

  @override
  String get srsStillDue => 'Nog te herhalen';

  @override
  String srsQuestionsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vragen te herhalen',
      one: '1 vraag te herhalen',
    );
    return '$_temp0';
  }

  @override
  String get srsBackToSpacedRepetition => 'Terug naar Spaced Repetition';

  @override
  String get srsHowWellKnew => 'Hoe goed kende je dit?';

  @override
  String get srsAgain => 'Opnieuw';

  @override
  String get srsHard => 'Moeilijk';

  @override
  String get srsGood => 'Goed';

  @override
  String get srsEasy => 'Makkelijk';

  @override
  String get durationNow => 'nu';

  @override
  String durationDays(int n) {
    return '${n}d';
  }

  @override
  String durationHours(int n) {
    return '${n}u';
  }

  @override
  String durationMinutes(int n) {
    return '${n}m';
  }

  @override
  String get quizCompleted => 'Quiz voltooid';

  @override
  String get noQuestions => 'Geen vragen';

  @override
  String get manageContentTitle => 'Inhoud beheren';

  @override
  String get addFolder => 'Map toevoegen';

  @override
  String get addQuiz => 'Quiz toevoegen';

  @override
  String get addQuestion => 'Vraag toevoegen';

  @override
  String get importJsonTooltip => 'JSON importeren';

  @override
  String get exportJsonTooltip => 'JSON exporteren';

  @override
  String get exportSeedDbTooltip => 'seed.db exporteren';

  @override
  String get importSuccess => 'Importeren geslaagd';

  @override
  String importFailed(Object error) {
    return 'Importeren mislukt: $error';
  }

  @override
  String exportFailed(Object error) {
    return 'Exporteren mislukt: $error';
  }

  @override
  String get folderContents => 'Mapinhoud';

  @override
  String get emptyFolderManage =>
      'Leeg. Tik op + om een map of quiz toe te voegen.';

  @override
  String get builtIn => 'Ingebouwd';

  @override
  String get builtInDebug => 'Ingebouwd (bewerkbaar in debug)';

  @override
  String get deleteFolderTitle => 'Map verwijderen?';

  @override
  String deleteFolderContent(String name) {
    return 'Dit verwijdert \"$name\" en alles daarin.';
  }

  @override
  String get deleteQuizTitle => 'Quiz verwijderen?';

  @override
  String deleteQuizContent(String name) {
    return 'Dit verwijdert \"$name\" en alle bijbehorende vragen.';
  }

  @override
  String get questionsSubtitle => 'Vragen';

  @override
  String get noQuestionsYet => 'Nog geen vragen. Voeg er een toe.';

  @override
  String get deleteQuestionTitle => 'Vraag verwijderen?';

  @override
  String get answerTypeMultipleChoiceChip => 'Meerkeuze';

  @override
  String get answerTypeTypedChip => 'Typen';

  @override
  String get answerTypeImageClickChip => 'Afbeelding klikken';

  @override
  String get editFolderAppBarTitle => 'Map bewerken';

  @override
  String get addFolderAppBarTitle => 'Map toevoegen';

  @override
  String get folderNameLabel => 'Mapnaam';

  @override
  String get folderImageOptional => 'Mapafbeelding (optioneel)';

  @override
  String get editQuizAppBarTitle => 'Quiz bewerken';

  @override
  String get addQuizAppBarTitle => 'Quiz toevoegen';

  @override
  String get titleLabel => 'Titel';

  @override
  String get quizImageOptional => 'Quizafbeelding (optioneel)';

  @override
  String get languageCodeLabel => 'Taalcode';

  @override
  String get languageCodeHint => 'bijv. en, nl, de, fr';

  @override
  String get editQuestionAppBarTitle => 'Vraag bewerken';

  @override
  String get addQuestionAppBarTitle => 'Vraag toevoegen';

  @override
  String get questionLabel => 'Vraag';

  @override
  String get answerTypeLabel => 'Antwoordtype';

  @override
  String get optionsLabel => 'Opties';

  @override
  String optionN(int n) {
    return 'Optie $n';
  }

  @override
  String get radioCorrectHint => 'Radioknop = juist antwoord';

  @override
  String get checkboxCorrectHint => 'Vink alle juiste antwoorden aan';

  @override
  String get addOption => 'Optie toevoegen';

  @override
  String get multipleCorrectAnswers => 'Meerdere juiste antwoorden';

  @override
  String get showCorrectCount => 'Aantal antwoorden tonen';

  @override
  String get showCorrectCountSubtitle =>
      'Vertel studenten hoeveel antwoorden ze moeten selecteren';

  @override
  String get checkAnswer => 'Antwoord controleren';

  @override
  String get selectAllThatApply => 'Selecteer alles wat van toepassing is';

  @override
  String selectNCorrectAnswers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selecteer $count juiste antwoorden',
      one: 'Selecteer 1 juist antwoord',
    );
    return '$_temp0';
  }

  @override
  String get selectAtLeastOneCorrect => 'Markeer minimaal één optie als juist';

  @override
  String get duplicateOption => 'Opties moeten uniek zijn';

  @override
  String get acceptedAnswersLabel => 'Geaccepteerde antwoorden';

  @override
  String acceptedAnswerN(int n) {
    return 'Geaccepteerd antwoord $n';
  }

  @override
  String get atLeastOneRequired => 'Minimaal één vereist';

  @override
  String get addVariant => 'Variant toevoegen';

  @override
  String get clickAreaImageLabel => 'Klikgebiedafbeelding';

  @override
  String get defineClickAreas => 'Klikgebieden definiëren';

  @override
  String editClickAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gebieden',
      one: '1 gebied',
    );
    return 'Klikgebieden bewerken ($_temp0)';
  }

  @override
  String areasDefinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gebieden',
      one: '1 gebied',
    );
    return '$_temp0 gedefinieerd ✓';
  }

  @override
  String get pleaseDefineClickArea => 'Definieer minstens één klikgebied';

  @override
  String get flashcardRandomize => 'Voor-/achterkant willekeurig';

  @override
  String get flashcardRandomizeSubtitle =>
      'Elke poging kiest willekeurig welke kant als eerste wordt getoond';

  @override
  String get flashcardFrontSide => 'Voorkant';

  @override
  String get flashcardBackSide => 'Achterkant';

  @override
  String get flashcardFrontTextOptional => 'Voorkant tekst (optioneel)';

  @override
  String get flashcardBackTextOptional => 'Achterkant tekst (optioneel)';

  @override
  String get flashcardFrontImageOptional => 'Voorkant afbeelding (optioneel)';

  @override
  String get flashcardBackImageOptional => 'Achterkant afbeelding (optioneel)';

  @override
  String get flashcardFrontRequired =>
      'Voorkant heeft minimaal tekst of een afbeelding nodig';

  @override
  String get flashcardBackRequired =>
      'Achterkant heeft minimaal tekst of een afbeelding nodig';

  @override
  String get questionImageOptional => 'Vraagafbeelding (optioneel)';

  @override
  String get explanationOptional => 'Uitleg (optioneel)';

  @override
  String get saveQuestion => 'Vraag opslaan';

  @override
  String get answerTypeMCLabel => 'Meerkeuze';

  @override
  String get answerTypeTypedLabel => 'Typen';

  @override
  String get answerTypeImageClickLabel => 'Afbeelding klikken';

  @override
  String get answerTypeFlashcardLabel => 'Flashcard';

  @override
  String get answerTypeSortingLabel => 'Sorteren';

  @override
  String get answerTypeSortingChip => 'Sorteren';

  @override
  String get sortingItemsLabel => 'Items (juiste volgorde, boven → onder)';

  @override
  String sortingItemN(int n) {
    return 'Item $n';
  }

  @override
  String get addItem => 'Item toevoegen';

  @override
  String get showPreFilled => 'Items vooraf tonen';

  @override
  String get showPreFilledSubtitle =>
      'Studenten slepen items op volgorde; uitschakelen om ze elk item te laten typen';

  @override
  String get checkOrder => 'Volgorde controleren';

  @override
  String get sortingDragHint => 'Slepen om te herordenen';

  @override
  String sortingCorrectAnswer(String answer) {
    return 'Juist: $answer';
  }

  @override
  String get unsavedChangesQuestion => 'Je vraagwijzigingen gaan verloren.';

  @override
  String get discardChangesTitle => 'Wijzigingen verwerpen?';

  @override
  String get discardChangesDefault =>
      'Je hebt niet-opgeslagen wijzigingen die verloren gaan.';

  @override
  String get keepEditing => 'Blijf bewerken';

  @override
  String get discard => 'Verwerpen';
}
