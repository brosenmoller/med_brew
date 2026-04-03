import 'dart:convert';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/category_data.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/models/answer_configs.dart';
import 'package:med_brew/models/answer_type.dart';

class QuestionService {
  QuestionService._internal();
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;

  bool _initialized = false;
  late AppDatabase _db;

  final Map<String, QuestionData> _questions = {};
  final Map<String, CategoryData> _categories = {};
  final Map<String, QuizData> _quizzes = {};

  Future<void> init(AppDatabase db) async {
    if (_initialized) return;
    _db = db;
    await _load();
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> _load() async {
    _questions.clear();
    _categories.clear();
    _quizzes.clear();

    final categories = await _db.getAllCategories();
    for (final cat in categories) {
      final quizzes = await _db.getQuizzesForCategory(cat.id);
      final quizIds = <String>[];

      for (final quiz in quizzes) {
        final questions = await _db.getQuestionsForQuiz(quiz.id);
        final questionIds = <String>[];

        for (final question in questions) {
          final questionId = question.id.toString();

          AnswerType answerType;
          try {
            answerType = AnswerType.values.firstWhere(
              (e) => e.toString().split('.').last == question.answerType,
            );
          } catch (_) {
            continue; // unknown answerType — skip
          }

          Map<String, dynamic> config;
          try {
            config = jsonDecode(question.answerConfig) as Map<String, dynamic>;
          } catch (_) {
            continue; // skip malformed records
          }

          questionIds.add(questionId);
          List<String> questionVariants;
          try {
            questionVariants = question.questionVariants != null
                ? List<String>.from(jsonDecode(question.questionVariants!))
                : [question.questionText];
          } catch (_) {
            questionVariants = [question.questionText];
          }

          _questions[questionId] = QuestionData(
            id: questionId,
            questionVariants: questionVariants,
            imagePath: question.imagePath,
            answerType: answerType,
            explanation: question.explanation,
            multipleChoiceConfig: answerType == AnswerType.multipleChoice
                ? MultipleChoiceConfig.fromJson(config)
                : null,
            typedAnswerConfig: answerType == AnswerType.typed
                ? TypedAnswerConfig.fromJson(config)
                : null,
            imageClickConfig: answerType == AnswerType.imageClick
                ? ImageClickConfig.fromJson(config)
                : null,
          );
        }

        final quizId = quiz.id.toString();
        quizIds.add(quizId);
        _quizzes[quizId] = QuizData(
          id: quizId,
          title: quiz.title,
          imagePath: quiz.imagePath,
          questionIds: questionIds,
        );
      }

      final categoryId = cat.id.toString();
      _categories[categoryId] = CategoryData(
        id: categoryId,
        title: cat.title,
        imagePath: cat.imagePath,
        quizIds: quizIds,
      );
    }

    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) throw Exception('QuestionService not initialized');
  }

  List<QuestionData> getAllQuestions() {
    _ensureInitialized();
    return _questions.values.toList();
  }

  List<CategoryData> getCategories() {
    _ensureInitialized();
    return _categories.values.toList();
  }

  List<QuizData> getQuizzesForCategory(String categoryId) {
    _ensureInitialized();
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