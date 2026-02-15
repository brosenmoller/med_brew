import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/widgets/multiple_choice_widget.dart';
import 'package:med_brew/widgets/typed_answer_widget.dart';
import 'package:med_brew/widgets/image_click_widget.dart';

class AnswerArea extends StatelessWidget {
  final QuestionData question;
  final bool locked;
  final Function(bool) onAnswered;

  const AnswerArea({
    super.key,
    required this.question,
    required this.locked,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.answerType) {
      case AnswerType.multipleChoice:
        return MultipleChoiceWidget(
            question: question, locked: locked, onAnswered: onAnswered);
      case AnswerType.typed:
        return TypedAnswerWidget(
            question: question, locked: locked, onAnswered: onAnswered);
      case AnswerType.imageClick:
        return ImageClickWidget(
            question: question, locked: locked, onAnswered: onAnswered);
    }
  }
}
