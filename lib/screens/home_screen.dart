import 'package:flutter/material.dart';
import 'package:med_brew/screens/category_overview_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'srs_overview_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final QuestionService service = QuestionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Med Brew")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () {
                // Navigate to normal quizzes/categories
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryOverviewScreen(),
                  ),
                );
              },
              child: const Text("Categories"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () {
                // Navigate to SRS Overview
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SrsOverviewScreen(),
                  ),
                );
              },
              child: const Text("Spaced Repetition"),
            ),
          ],
        ),
      ),
    );
  }
}
