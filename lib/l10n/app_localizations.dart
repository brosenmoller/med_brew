import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('en'),
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Med Brew'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @navBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get navBrowse;

  /// No description provided for @navBrowseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore quizzes & categories'**
  String get navBrowseSubtitle;

  /// No description provided for @navSpacedRepetition.
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition'**
  String get navSpacedRepetition;

  /// No description provided for @navSpacedRepetitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your due cards'**
  String get navSpacedRepetitionSubtitle;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved quizzes'**
  String get navFavoritesSubtitle;

  /// No description provided for @navManageContent.
  ///
  /// In en, this message translates to:
  /// **'Manage Content'**
  String get navManageContent;

  /// No description provided for @navManageContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create & edit questions'**
  String get navManageContentSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsResetSrs.
  ///
  /// In en, this message translates to:
  /// **'Reset all SRS data'**
  String get settingsResetSrs;

  /// No description provided for @settingsResetSrsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset SRS Data'**
  String get settingsResetSrsDialogTitle;

  /// No description provided for @settingsResetSrsDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all SRS data? This cannot be undone.'**
  String get settingsResetSrsDialogContent;

  /// No description provided for @settingsResetSrsSuccess.
  ///
  /// In en, this message translates to:
  /// **'All SRS data reset'**
  String get settingsResetSrsSuccess;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get settingsLanguageDutch;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @foldersSection.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersSection;

  /// No description provided for @quizzesSection.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzesSection;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get emptyFolder;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite quizzes yet.'**
  String get favoritesEmpty;

  /// No description provided for @srsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition'**
  String get srsTitle;

  /// No description provided for @srsNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No spaced repetition questions available'**
  String get srsNoQuestions;

  /// No description provided for @srsDue.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String srsDue(int count);

  /// No description provided for @srsCards.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String srsCards(int count);

  /// No description provided for @srsOldestOverdue.
  ///
  /// In en, this message translates to:
  /// **'oldest {time} overdue'**
  String srsOldestOverdue(String time);

  /// No description provided for @srsNextIn.
  ///
  /// In en, this message translates to:
  /// **'next in {time}'**
  String srsNextIn(String time);

  /// No description provided for @srsStartNormalQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start normal quiz'**
  String get srsStartNormalQuiz;

  /// No description provided for @srsNoSrsScheduling.
  ///
  /// In en, this message translates to:
  /// **'No SRS scheduling'**
  String get srsNoSrsScheduling;

  /// No description provided for @srsRemoveFromSrs.
  ///
  /// In en, this message translates to:
  /// **'Remove from SRS'**
  String get srsRemoveFromSrs;

  /// No description provided for @srsRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from spaced repetition?'**
  String get srsRemoveDialogTitle;

  /// No description provided for @srsRemoveDialogContent.
  ///
  /// In en, this message translates to:
  /// **'All SRS progress for \"{quizTitle}\" will be lost. This cannot be undone.'**
  String srsRemoveDialogContent(String quizTitle);

  /// No description provided for @srsNoQuestionsDue.
  ///
  /// In en, this message translates to:
  /// **'No questions due'**
  String get srsNoQuestionsDue;

  /// No description provided for @srsSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get srsSessionComplete;

  /// No description provided for @srsQuestionsReviewed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question reviewed} other{{count} questions reviewed}}'**
  String srsQuestionsReviewed(int count);

  /// No description provided for @srsAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get srsAllCaughtUp;

  /// No description provided for @srsNoMoreDue.
  ///
  /// In en, this message translates to:
  /// **'No more questions due right now.'**
  String get srsNoMoreDue;

  /// No description provided for @srsStillDue.
  ///
  /// In en, this message translates to:
  /// **'Still due'**
  String get srsStillDue;

  /// No description provided for @srsQuestionsDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question due} other{{count} questions due}}'**
  String srsQuestionsDue(int count);

  /// No description provided for @srsBackToSpacedRepetition.
  ///
  /// In en, this message translates to:
  /// **'Back to Spaced Repetition'**
  String get srsBackToSpacedRepetition;

  /// No description provided for @srsHowWellKnew.
  ///
  /// In en, this message translates to:
  /// **'How well did you know this?'**
  String get srsHowWellKnew;

  /// No description provided for @srsAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get srsAgain;

  /// No description provided for @srsHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get srsHard;

  /// No description provided for @srsGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get srsGood;

  /// No description provided for @srsEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get srsEasy;

  /// No description provided for @durationNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get durationNow;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String durationDays(int n);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String durationHours(int n);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String durationMinutes(int n);

  /// No description provided for @quizCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quiz Completed'**
  String get quizCompleted;

  /// No description provided for @noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions'**
  String get noQuestions;

  /// No description provided for @manageContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Content'**
  String get manageContentTitle;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolder;

  /// No description provided for @addQuiz.
  ///
  /// In en, this message translates to:
  /// **'Add Quiz'**
  String get addQuiz;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestion;

  /// No description provided for @importJsonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJsonTooltip;

  /// No description provided for @exportJsonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJsonTooltip;

  /// No description provided for @exportSeedDbTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export seed.db'**
  String get exportSeedDbTooltip;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @folderContents.
  ///
  /// In en, this message translates to:
  /// **'Folder contents'**
  String get folderContents;

  /// No description provided for @emptyFolderManage.
  ///
  /// In en, this message translates to:
  /// **'Empty. Tap + to add a folder or quiz.'**
  String get emptyFolderManage;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtIn;

  /// No description provided for @builtInDebug.
  ///
  /// In en, this message translates to:
  /// **'Built-in (editable in debug)'**
  String get builtInDebug;

  /// No description provided for @deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder?'**
  String get deleteFolderTitle;

  /// No description provided for @deleteFolderContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete \"{name}\" and everything inside it.'**
  String deleteFolderContent(String name);

  /// No description provided for @deleteQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Quiz?'**
  String get deleteQuizTitle;

  /// No description provided for @deleteQuizContent.
  ///
  /// In en, this message translates to:
  /// **'This will delete \"{name}\" and all its questions.'**
  String deleteQuizContent(String name);

  /// No description provided for @questionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questionsSubtitle;

  /// No description provided for @noQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions yet. Add one below.'**
  String get noQuestionsYet;

  /// No description provided for @deleteQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Question?'**
  String get deleteQuestionTitle;

  /// No description provided for @answerTypeMultipleChoiceChip.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get answerTypeMultipleChoiceChip;

  /// No description provided for @answerTypeTypedChip.
  ///
  /// In en, this message translates to:
  /// **'Typed'**
  String get answerTypeTypedChip;

  /// No description provided for @answerTypeImageClickChip.
  ///
  /// In en, this message translates to:
  /// **'Image click'**
  String get answerTypeImageClickChip;

  /// No description provided for @editFolderAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Folder'**
  String get editFolderAppBarTitle;

  /// No description provided for @addFolderAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolderAppBarTitle;

  /// No description provided for @folderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderNameLabel;

  /// No description provided for @folderImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Folder image (optional)'**
  String get folderImageOptional;

  /// No description provided for @editQuizAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Quiz'**
  String get editQuizAppBarTitle;

  /// No description provided for @addQuizAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Quiz'**
  String get addQuizAppBarTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @quizImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Quiz image (optional)'**
  String get quizImageOptional;

  /// No description provided for @languageCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Language code'**
  String get languageCodeLabel;

  /// No description provided for @languageCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. en, nl, de, fr'**
  String get languageCodeHint;

  /// No description provided for @editQuestionAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get editQuestionAppBarTitle;

  /// No description provided for @addQuestionAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestionAppBarTitle;

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionLabel;

  /// No description provided for @answerTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer type'**
  String get answerTypeLabel;

  /// No description provided for @optionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsLabel;

  /// No description provided for @optionN.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String optionN(int n);

  /// No description provided for @radioCorrectHint.
  ///
  /// In en, this message translates to:
  /// **'Radio button = correct answer'**
  String get radioCorrectHint;

  /// No description provided for @checkboxCorrectHint.
  ///
  /// In en, this message translates to:
  /// **'Check all correct answers'**
  String get checkboxCorrectHint;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @multipleCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'Multiple correct answers'**
  String get multipleCorrectAnswers;

  /// No description provided for @showCorrectCount.
  ///
  /// In en, this message translates to:
  /// **'Show answer count'**
  String get showCorrectCount;

  /// No description provided for @showCorrectCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell students how many answers to select'**
  String get showCorrectCountSubtitle;

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get checkAnswer;

  /// No description provided for @selectAllThatApply.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get selectAllThatApply;

  /// No description provided for @selectNCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Select 1 correct answer} other{Select {count} correct answers}}'**
  String selectNCorrectAnswers(int count);

  /// No description provided for @selectAtLeastOneCorrect.
  ///
  /// In en, this message translates to:
  /// **'Please mark at least one option as correct'**
  String get selectAtLeastOneCorrect;

  /// No description provided for @acceptedAnswersLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepted Answers'**
  String get acceptedAnswersLabel;

  /// No description provided for @acceptedAnswerN.
  ///
  /// In en, this message translates to:
  /// **'Accepted answer {n}'**
  String acceptedAnswerN(int n);

  /// No description provided for @atLeastOneRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one required'**
  String get atLeastOneRequired;

  /// No description provided for @addVariant.
  ///
  /// In en, this message translates to:
  /// **'Add variant'**
  String get addVariant;

  /// No description provided for @clickAreaImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Click area image'**
  String get clickAreaImageLabel;

  /// No description provided for @defineClickAreas.
  ///
  /// In en, this message translates to:
  /// **'Define Click Areas'**
  String get defineClickAreas;

  /// No description provided for @editClickAreas.
  ///
  /// In en, this message translates to:
  /// **'Edit Click Areas ({count, plural, =1{1 area} other{{count} areas}})'**
  String editClickAreas(int count);

  /// No description provided for @areasDefinedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 area} other{{count} areas}} defined ✓'**
  String areasDefinedCount(int count);

  /// No description provided for @pleaseDefineClickArea.
  ///
  /// In en, this message translates to:
  /// **'Please define at least one click area'**
  String get pleaseDefineClickArea;

  /// No description provided for @flashcardRandomize.
  ///
  /// In en, this message translates to:
  /// **'Randomize front/back sides'**
  String get flashcardRandomize;

  /// No description provided for @flashcardRandomizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each attempt randomly picks which side to show first'**
  String get flashcardRandomizeSubtitle;

  /// No description provided for @flashcardFrontSide.
  ///
  /// In en, this message translates to:
  /// **'Front side'**
  String get flashcardFrontSide;

  /// No description provided for @flashcardBackSide.
  ///
  /// In en, this message translates to:
  /// **'Back side'**
  String get flashcardBackSide;

  /// No description provided for @flashcardFrontTextOptional.
  ///
  /// In en, this message translates to:
  /// **'Front text (optional)'**
  String get flashcardFrontTextOptional;

  /// No description provided for @flashcardBackTextOptional.
  ///
  /// In en, this message translates to:
  /// **'Back text (optional)'**
  String get flashcardBackTextOptional;

  /// No description provided for @flashcardFrontImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Front image (optional)'**
  String get flashcardFrontImageOptional;

  /// No description provided for @flashcardBackImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Back image (optional)'**
  String get flashcardBackImageOptional;

  /// No description provided for @flashcardFrontRequired.
  ///
  /// In en, this message translates to:
  /// **'Front side needs at least text or an image'**
  String get flashcardFrontRequired;

  /// No description provided for @flashcardBackRequired.
  ///
  /// In en, this message translates to:
  /// **'Back side needs at least text or an image'**
  String get flashcardBackRequired;

  /// No description provided for @questionImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Question image (optional)'**
  String get questionImageOptional;

  /// No description provided for @explanationOptional.
  ///
  /// In en, this message translates to:
  /// **'Explanation (optional)'**
  String get explanationOptional;

  /// No description provided for @saveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save Question'**
  String get saveQuestion;

  /// No description provided for @answerTypeMCLabel.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get answerTypeMCLabel;

  /// No description provided for @answerTypeTypedLabel.
  ///
  /// In en, this message translates to:
  /// **'Typed'**
  String get answerTypeTypedLabel;

  /// No description provided for @answerTypeImageClickLabel.
  ///
  /// In en, this message translates to:
  /// **'Image Click'**
  String get answerTypeImageClickLabel;

  /// No description provided for @answerTypeFlashcardLabel.
  ///
  /// In en, this message translates to:
  /// **'Flashcard'**
  String get answerTypeFlashcardLabel;

  /// No description provided for @unsavedChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Your question changes will be lost.'**
  String get unsavedChangesQuestion;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesDefault.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes that will be lost.'**
  String get discardChangesDefault;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
