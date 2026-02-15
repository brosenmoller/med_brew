import 'package:flutter/material.dart';
import 'package:med_brew/models/category_data.dart';
import 'package:med_brew/screens/quiz_session_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/quiz_tile.dart' show QuizTile;

class QuizOverviewScreen extends StatelessWidget {
  final CategoryData category;
  final QuestionService questionService = QuestionService();

  QuizOverviewScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final quizzes = questionService.getQuizzesForCategory(category.id);

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 6;

    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
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

          return QuizTile(
            quiz: quiz,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizSessionScreen(quizData: quiz),
                ),
              );
            },
          );
        },
      ),
    );
  }
}