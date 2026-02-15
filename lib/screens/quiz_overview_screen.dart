import 'package:flutter/material.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/screens/quiz_session_screen.dart';

class QuizOverviewScreen extends StatelessWidget {
  final String category;

  QuizOverviewScreen({super.key, required this.category});

  final QuestionService service = QuestionService();

  @override
  Widget build(BuildContext context) {
    final quizzes = service.getQuizzesForCategory(category);

    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth < 600) { // mobile
      crossAxisCount = 2;
    } else { // tablet / desktop / laptop
      crossAxisCount = 6;
    }

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final quiz = quizzes[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QuizSessionScreen(quizName: quiz),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  quiz,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
