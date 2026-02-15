import 'package:flutter/material.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/screens/quiz_session_screen.dart';

class QuizOverviewScreen extends StatefulWidget {
  final String category;

  const QuizOverviewScreen({super.key, required this.category});

  @override
  State<QuizOverviewScreen> createState() => _QuizOverviewScreenState();
}

class _QuizOverviewScreenState extends State<QuizOverviewScreen> {
  final QuestionService service = QuestionService();
  final SrsService srsService = SrsService();

  // In-memory favorite tracking (can also persist in Hive later)
  final Set<String> favorites = {};

  @override
  Widget build(BuildContext context) {
    final quizzes = service.getQuizzesForCategory(widget.category);

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 2 : 6;

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
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

          // Fetch all questions for this quiz
          final questions = service.getQuestionsForQuiz(quiz);

          // Determine SRS state from persisted user data
          bool isSrsEnabled = questions.isNotEmpty
              ? srsService.getUserData(questions.first).spacedRepetitionEnabled
              : false;

          bool isFavorite = favorites.contains(quiz);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizSessionScreen(quizName: quiz),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Quiz name centered
                  Center(
                    child: Text(
                      quiz,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Top-right toggle icons
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // SRS toggle
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: isSrsEnabled ? Colors.blue : Colors.white,
                            size: 20,
                          ),
                          onPressed: () async {
                            if (questions.isEmpty) return;
                            setState(() {
                              isSrsEnabled = !isSrsEnabled;
                            });

                            // Update Hive for all questions in this quiz
                            for (var q in questions) {
                              var userData = srsService.getUserData(q);
                              userData.spacedRepetitionEnabled = isSrsEnabled;
                              await srsService.updateUserData(userData);
                            }
                          },
                        ),

                        // Favorite toggle
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: Colors.yellowAccent,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isFavorite) {
                                favorites.remove(quiz);
                              } else {
                                favorites.add(quiz);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
