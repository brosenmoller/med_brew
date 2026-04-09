import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/user_question_data.dart' show SrsQuality;
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/screens/question_display/question_display_screen.dart';
import 'package:med_brew/screens/srs_completion_screen.dart';

class SrsSessionScreen extends StatefulWidget {
  final List<QuestionData> questions;
  final String sessionTitle;

  const SrsSessionScreen({
    super.key,
    required this.questions,
    required this.sessionTitle,
  });

  @override
  State<SrsSessionScreen> createState() => _SrsSessionScreenState();
}

class _SrsSessionScreenState extends State<SrsSessionScreen> {
  final SrsService _srsService = SrsService();

  int currentIndex = 0;
  int correctAnswers = 0;

  void _nextQuestion(bool wasCorrect) {
    if (wasCorrect) correctAnswers++;

    if (currentIndex < widget.questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SrsCompletionScreen(
            completedQuizTitle: widget.sessionTitle,
            reviewedCount: widget.questions.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sessionTitle)),
        body: const Center(child: Text("No questions due")),
      );
    }

    final question = widget.questions[currentIndex];

    return QuestionDisplayScreen(
      key: ValueKey(currentIndex),
      question: question,
      spacedRepetitionMode: true,
      onContinue: (wasCorrect, quality) async {
        if (quality != null) {
          await _srsService.updateAfterAnswer(question, quality);
        } else if (!wasCorrect) {
          await _srsService.updateAfterAnswer(question, SrsQuality.again);
        }
        _nextQuestion(wasCorrect);
      },
    );
  }
}