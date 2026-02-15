import 'package:hive/hive.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/services/question_service.dart';

class SrsService {
  static final SrsService _instance = SrsService._internal();
  factory SrsService() => _instance;
  SrsService._internal();
  bool _initialized = false;

  static const String boxName = 'userQuestions';
  late Box<UserQuestionData> _userQuestionBox;

  /// Initialize Hive box
  Future<void> init() async {
    if (_initialized) { return; }

    _userQuestionBox = await Hive.openBox<UserQuestionData>(boxName);
    _initialized = true;
  }

  /// Get UserQuestionData for a specific question
  UserQuestionData getUserData(QuestionData question) {
    return _userQuestionBox.get(question.id) ?? UserQuestionData(questionId: question.id);
  }

  /// Sets the User Data's spacedRepetitionEnabled for this question to 'enabled'
  Future<void> setQuestionSrs(QuestionData question, bool enabled) async {
    final userData = getUserData(question);
    userData.spacedRepetitionEnabled = enabled;
    await _userQuestionBox.put(question.id, userData);
  }

  /// Puts the Updated User Data into Hive
  Future<void> updateUserData(UserQuestionData userData) async {
    await _userQuestionBox.put(userData.questionId, userData);
  }

  /// Update user data after answering a question
  Future<void> updateAfterAnswer(QuestionData question, SrsQuality quality) async {
    final userData = getUserData(question);
    userData.updateAfterAnswer(quality);
    await _userQuestionBox.put(question.id, userData);
  }

  /// Return all questions due for review from a given list
  List<QuestionData> getDueQuestions(List<QuestionData> allQuestions) {
    return allQuestions
        .where((q) => getUserData(q).isDue)
        .toList();
  }

  /// Return all due questions across all categories/quizzes
  List<QuestionData> getAllDueQuestions() {
    final allQuestions = QuestionService().getAllQuestions();
    return getDueQuestions(allQuestions);
  }

  /// Return all UserQuestionData
  List<UserQuestionData> getAllUserData() {
    return _userQuestionBox.values.toList();
  }

  /// Reset all user SRS data (optional, for testing)
  Future<void> resetAll() async {
    await _userQuestionBox.clear();
  }

  /// Get next question for a category or tag
  QuestionData? getNextQuestion(
      List<QuestionData> allQuestions, String category) {
    final due = getDueQuestions(allQuestions)
        .where((question) => question.quizTags.contains(category))
        .toList();
    if (due.isEmpty) return null;
    due.shuffle();
    return due.first;
  }
}
