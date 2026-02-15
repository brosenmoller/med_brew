import 'package:flutter/material.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/screens/quiz_overview_screen.dart';
import 'package:med_brew/widgets/category_tile.dart';

class CategoryOverviewScreen extends StatelessWidget {
  CategoryOverviewScreen({super.key});

  final QuestionService service = QuestionService();

  @override
  Widget build(BuildContext context) {
    final categories = service.getCategories();

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 6;

    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];

          return CategoryTile(
            category: category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizOverviewScreen(category: category),
                ),
              );
            },
          );
        },
      ),
    );
  }
}