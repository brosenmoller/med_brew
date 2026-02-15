import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/category_data.dart';
import 'package:med_brew/models/quiz_data.dart';

class QuestionService {
  QuestionService._internal();
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;

  bool _initialized = false;

  final Map<String, QuestionData> _questions = {};
  final Map<String, CategoryData> _categories = {};
  final Map<String, QuizData> _quizzes = {};

  /// Initialize everything
  Future<void> init({
    required String questionsAsset,
    required String categoriesAsset,
    required String quizzesAsset,
  }) async {
    if (_initialized) return;

    await _loadQuestions(questionsAsset);
    await _loadCategories(categoriesAsset);
    await _loadQuizzes(quizzesAsset);

    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception("QuestionService not initialized");
    }
  }

  // ----------------------------
  // Loading
  // ----------------------------

  Future<void> _loadQuestions(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonData = json.decode(jsonString);

    for (final q in jsonData) {
      final question = QuestionData.fromJson(q);
      _questions[question.id] = question;
    }
  }

  Future<void> _loadCategories(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonData = json.decode(jsonString);

    for (final c in jsonData) {
      final category = CategoryData.fromJson(c);
      _categories[category.id] = category;
    }
  }

  Future<void> _loadQuizzes(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonData = json.decode(jsonString);

    for (final question in jsonData) {
      final quiz = QuizData.fromJson(question);
      _quizzes[quiz.id] = quiz;
    }
  }

  // ----------------------------
  // Public Getters
  // ----------------------------

  List<QuestionData> getAllQuestions() {
    _ensureInitialized();
    return _questions.values.toList();
  }

  List<CategoryData> getCategories() {
    _ensureInitialized();
    return _categories.values.toList();
  }

  List<QuizData> getQuizzesForCategory(String categoryId) {
    final category = _categories[categoryId];
    if (category == null) return [];

    return category.quizIds
        .map((id) => _quizzes[id])
        .whereType<QuizData>()
        .toList();
  }

  List<QuestionData> getQuestionsForQuiz(String quizId) {
    _ensureInitialized();

    final quiz = _quizzes[quizId];
    if (quiz == null) return [];

    return quiz.questionIds
        .map((id) => _questions[id])
        .whereType<QuestionData>()
        .toList();
  }

  QuestionData? getQuestion(String id) => _questions[id];
  QuizData? getQuiz(String id) => _quizzes[id];
  CategoryData? getCategory(String id) => _categories[id];
}
