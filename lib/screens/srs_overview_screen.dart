import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/user_question_data.dart' show SrsQuality;
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/screens/question_display/question_display_screen.dart';

class SrsOverviewScreen extends StatelessWidget {
  SrsOverviewScreen({super.key});

  final QuestionService questionService = QuestionService();
  final SrsService srsService = SrsService();

  @override
  Widget build(BuildContext context) {
    final allQuestions = questionService.getAllQuestions();
    final categories = questionService.getCategories();

    // Map: category -> quiz -> questions
    final Map<String, Map<String, List<QuestionData>>> srsData = {};

    for (var cat in categories) {
      final quizzes = questionService.getQuizzesForCategory(cat);
      final Map<String, List<QuestionData>> quizMap = {};
      for (var quiz in quizzes) {
        final questions = allQuestions
            .where((q) => q.quizTags.first == cat && q.quizTags[1] == quiz)
            .toList();
        if (questions.isNotEmpty) {
          quizMap[quiz] = questions;
        }
      }
      srsData[cat] = quizMap;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spaced Repetition")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: srsData.entries.map((categoryEntry) {
            final cat = categoryEntry.key;
            final quizzes = categoryEntry.value;

            if (quizzes.isEmpty) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(cat),
                  subtitle: const Text("No quizzes with SRS questions"),
                ),
              );
            }

            // Determine if any quiz in this category has due questions
            final hasDueQuestions = quizzes.values.any((quizQuestions) =>
                quizQuestions.any((q) => srsService.getUserData(q).isDue));

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                initiallyExpanded: hasDueQuestions,
                title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: quizzes.entries.map((quizEntry) {
                  final quizName = quizEntry.key;
                  final questions = quizEntry.value;

                  final dueQuestions = questions
                      .where((q) => srsService.getUserData(q).isDue)
                      .toList();
                  final hasDue = dueQuestions.isNotEmpty;

                  String oldestText = "N/A";
                  if (hasDue) {
                    final oldest = dueQuestions
                        .map((q) => srsService.getUserData(q).nextReview)
                        .reduce((a, b) => a.isBefore(b) ? a : b);
                    oldestText = _formatDuration(DateTime.now().difference(oldest));
                  }

                  return ListTile(
                    title: Text(quizName),
                    subtitle: Text("${dueQuestions.length} questions due, oldest: $oldestText"),
                    trailing: hasDue
                        ? ElevatedButton(
                      onPressed: () => _startQuiz(context, dueQuestions),
                      child: const Text("Start"),
                    )
                        : null,
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, List<QuestionData> questions) {
    int currentIndex = 0;

    void navigateNext() {
      if (currentIndex >= questions.length) {
        Navigator.pop(context);
        return;
      }

      final question = questions[currentIndex];
      currentIndex++;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionDisplayScreen(
            question: question,
            spacedRepetitionMode: true,
            onContinue: (wasCorrect) async {
              await SrsService().updateAfterAnswer(
                  question, wasCorrect ? SrsQuality.good : SrsQuality.again);
              navigateNext();
            },
          ),
        ),
      );
    }

    navigateNext();
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return "${duration.inDays}d";
    if (duration.inHours > 0) return "${duration.inHours}h";
    if (duration.inMinutes > 0) return "${duration.inMinutes}m";
    return "now";
  }
}
