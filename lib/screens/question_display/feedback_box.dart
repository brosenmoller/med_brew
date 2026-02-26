import 'package:flutter/material.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/models/question_data.dart';
import 'question_display_screen.dart';

class FeedbackBox extends StatelessWidget {
  final QuestionData question;
  final AnswerState answerState;

  const FeedbackBox({
    super.key,
    required this.question,
    required this.answerState,
  });

  String get correctAnswerText {
    switch (question.answerType) {
      case AnswerType.multipleChoice:
        final correctIndex = question.multipleChoiceConfig!.correctIndex;
        return question.multipleChoiceConfig!.options[correctIndex];
      case AnswerType.typed:
        return question.typedAnswerConfig!.acceptedAnswers.join(", ");
      case AnswerType.imageClick:
        return "Correct area";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = answerState == AnswerState.correct;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // For wide screens, limit width to 50% or max 600px
        final contentWidth = maxWidth > 800
            ? maxWidth * 0.5
            : maxWidth - 32; // subtract horizontal margin for mobile

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCorrect ? "Correct!" : "Incorrect",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isCorrect)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Correct Answer: $correctAnswerText",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
