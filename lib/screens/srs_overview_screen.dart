import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/screens/srs_session_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';

class SrsOverviewScreen extends StatelessWidget {
  SrsOverviewScreen({super.key});

  final QuestionService questionService = QuestionService();
  final SrsService srsService = SrsService();

  @override
  Widget build(BuildContext context) {
    final categories = questionService.getCategories();
    final srsData = <String, Map<String, List<QuestionData>>>{};

    for (final category in categories) {
      final quizzes = category.quizIds
          .map((quizId) => questionService.getQuiz(quizId))
          .whereType<QuizData>()
          .toList();

      final quizMap = <String, List<QuestionData>>{};

      for (final quiz in quizzes) {
        final questions = quiz.questionIds
            .map((qId) => questionService.getQuestion(qId))
            .whereType<QuestionData>()
            .where((q) => srsService.getUserData(q).spacedRepetitionEnabled)
            .toList();

        if (questions.isNotEmpty) {
          quizMap[quiz.id] = questions;
        }
      }

      if (quizMap.isNotEmpty) {
        srsData[category.id] = quizMap;
      }
    }

    if (srsData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Spaced Repetition")),
        body: const Center(child: Text("No spaced repetition questions available")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spaced Repetition")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: srsData.entries.map((categoryEntry) {
            final cat = categoryEntry.key;
            final quizzes = categoryEntry.value;

            // Determine if any quiz in this category has due questions
            final hasDueQuestions = quizzes.values.any((quizQuestions) => quizQuestions.any((q) => srsService.getUserData(q).isDue));

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                initiallyExpanded: hasDueQuestions, // expand if any due
                title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: quizzes.entries.map((quizEntry) {
                  final quizName = quizEntry.key;
                  final questions = quizEntry.value;

                  final dueQuestions = questions
                      .where((q) => srsService.getUserData(q).isDue)
                      .toList();
                  final hasDue = dueQuestions.isNotEmpty;

                  String timingText;

                  if (hasDue) {
                    final dueDates = dueQuestions.map((q) => srsService.getUserData(q).nextReview);
                    final oldestDue = dueDates.fold(dueDates.first, (a, b) => a.isBefore(b) ? a : b);
                    timingText = "oldest due: ${_formatDuration(DateTime.now().difference(oldestDue))} ago";
                  } else {
                    final upcomingDates = questions.map((q) => srsService.getUserData(q).nextReview);
                    final nextUpcoming = upcomingDates.fold(upcomingDates.first, (a, b) => a.isBefore(b) ? a : b);
                    timingText = "next due: ${_formatDuration(nextUpcoming.difference(DateTime.now()))}";
                  }

                  return ListTile(
                    title: Text(quizName),
                    subtitle: Text("${dueQuestions.length} questions due, $timingText"),
                    trailing: hasDue
                        ? ElevatedButton(
                      onPressed: () => _startQuiz(context, dueQuestions, quizName),
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

  void _startQuiz(BuildContext context, List<QuestionData> questions, String quizName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SrsSessionScreen(
          questions: questions,
          sessionTitle: quizName,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return "${duration.inDays}d";
    if (duration.inHours > 0) return "${duration.inHours}h";
    if (duration.inMinutes > 0) return "${duration.inMinutes}m";
    return "now";
  }
}
