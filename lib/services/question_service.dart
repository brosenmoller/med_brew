import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/data/question_repository.dart';

class QuestionService {
  QuestionService._internal();
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;

  List<QuestionData> getAllQuestions() {
    return QuestionRepository.allQuestions;
  }

  /// Level 1: Categories
  List<String> getCategories() {
    return getAllQuestions().map((q) => q.quizTags.first).toSet().toList();
  }

  /// Level 2: Quizzes in a category
  List<String> getQuizzesForCategory(String category) {
    final questionsInCategory = getAllQuestions().where((q) => q.quizTags.isNotEmpty && q.quizTags.first == category);

    final quizzes = <String>{}; // use a set to avoid duplicates

    for (QuestionData question in questionsInCategory) {
      if (question.quizTags.length > 1) {
        quizzes.addAll(question.quizTags.sublist(1));
      }
    }

    return quizzes.toList();
  }

  /// Questions for a quiz
  List<QuestionData> getQuestionsForQuiz(String quizName) {
    return getAllQuestions().where((q) => q.quizTags.contains(quizName)).toList();
  }
}
