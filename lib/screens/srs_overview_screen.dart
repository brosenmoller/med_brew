import 'package:flutter/material.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/screens/question_display/question_display_screen.dart';

class SrsOverviewScreen extends StatelessWidget {
  SrsOverviewScreen({super.key});

  final QuestionService questionService = QuestionService();
  final SrsService srsService = SrsService();

  @override
  Widget build(BuildContext context) {
    final allQuestions = questionService.getAllQuestions();
    final categories = questionService.getCategories();

    // Compute due questions per category
    final Map<String, List<QuestionData>> duePerCategory = {};
    for (var cat in categories) {
      duePerCategory[cat] = allQuestions
          .where((q) => q.quizTags.contains(cat) && srsService.getUserData(q).isDue)
          .toList();
    }

    // Find first category with due questions
    String? firstDueCategory;
    for (var cat in categories) {
      if (duePerCategory[cat]!.isNotEmpty) {
        firstDueCategory = cat;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spaced Repetition")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (firstDueCategory != null)
              ElevatedButton(
                onPressed: () {
                  _startCategory(context, firstDueCategory!, duePerCategory[firstDueCategory!]!);
                },
                child: Text("Start first due: $firstDueCategory"),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: categories.map((cat) {
                  final dueList = duePerCategory[cat]!;
                  if (dueList.isEmpty) return const SizedBox.shrink();

                  // Find oldest question due
                  final oldest = dueList
                      .map((q) => srsService.getUserData(q).nextReview)
                      .reduce((a, b) => a.isBefore(b) ? a : b);

                  final oldestDuration = DateTime.now().difference(oldest);
                  final oldestText = _formatDuration(oldestDuration);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(cat),
                      subtitle: Text("${dueList.length} questions due, oldest: $oldestText"),
                      trailing: ElevatedButton(
                        onPressed: () => _startCategory(context, cat, dueList),
                        child: const Text("Start"),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCategory(BuildContext context, String category, List<QuestionData> questions) {
    // Automatically navigate through all due questions in this category
    int currentIndex = 0;

    void navigateNext() {
      if (currentIndex >= questions.length) {
        Navigator.pop(context); // finished category
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
              // Automatically update SRS for correct/wrong answer
              await SrsService().updateAfterAnswer(
                  question, wasCorrect ? SrsQuality.good : SrsQuality.again);

              // Navigate to the next question
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
