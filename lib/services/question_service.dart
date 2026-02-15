import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/data/question_repository.dart';

class QuestionService {

  final List<QuestionData> _questions =
      QuestionRepository.allQuestions;

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