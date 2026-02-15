import 'package:flutter/material.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/screens/question_display_screen.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/screens/quiz_completion_screen.dart';

class QuizSessionScreen extends StatefulWidget {
  final String quizName;
  final bool shuffle;

  const QuizSessionScreen({super.key, required this.quizName, this.shuffle = true});

  @override
  State<QuizSessionScreen> createState() =>
      _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final QuestionService service = QuestionService();

  late List<QuestionData> questions = [];
  int currentIndex = 0;
  int correctAnswers = 0;
  int totalQuestions = 0;

  @override
  void initState() {
    super.initState();

    questions = service.getQuestionsForQuiz(widget.quizName);
    totalQuestions = questions.length;

    if (widget.shuffle) {
      questions.shuffle();
    }
  }

  void _nextQuestion(bool wasCorrect) {
    if (wasCorrect) {
      correctAnswers++;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizCompletionScreen(
            quizName: widget.quizName,
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No questions")),
      );
    }

    return QuestionDisplayScreen(
      card: questions[currentIndex],
      spacedRepetitionMode: false,
      onContinue: (wasCorrect) {
        _nextQuestion(wasCorrect);
      },
    );
  }
}
