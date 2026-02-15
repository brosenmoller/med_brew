import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/data/question_repository.dart';

class QuestionService {
  QuestionService._internal();
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  final List<QuestionData> _questions = QuestionRepository.allQuestions;

  List<QuestionData> getAllQuestions() {
    return _questions;
  }

  /// Level 1: Categories
  List<String> getCategories() {
    return _questions
        .map((q) => q.quizTags.first)
        .toSet()
        .toList();
  }

  /// Level 2: Quizzes in a category
  List<String> getQuizzesForCategory(String category) {
    return _questions
        .where((q) => q.quizTags.first == category)
        .map((q) => q.quizTags[1])
        .toSet()
        .toList();
  }

  /// Questions for a quiz
  List<QuestionData> getQuestionsForQuiz(String quizName) {
    return _questions
        .where((q) => q.quizTags.contains(quizName))
        .toList();
  }
}
