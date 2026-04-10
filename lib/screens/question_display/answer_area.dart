import 'package:flutter/material.dart';
import 'package:med_brew/models/answer_state.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/widgets/multiple_choice_widget.dart';
import 'package:med_brew/widgets/typed_answer_widget.dart';
import 'package:med_brew/widgets/image_click_widget.dart';
import 'package:med_brew/widgets/flashcard_widget.dart';
import 'package:med_brew/widgets/sorting_widget.dart';

class AnswerArea extends StatelessWidget {
  final QuestionData question;
  final bool locked;
  final AnswerState answerState;
  final Function(bool) onAnswered;
  final bool spacedRepetitionMode;

  const AnswerArea({
    super.key,
    required this.question,
    required this.locked,
    required this.answerState,
    required this.onAnswered,
    this.spacedRepetitionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.answerType) {
      case AnswerType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          locked: locked,
          answerState: answerState,
          onAnswered: onAnswered,
        );
      case AnswerType.typed:
        return TypedAnswerWidget(
          question: question,
          locked: locked,
          answerState: answerState,
          onAnswered: onAnswered,
        );
      case AnswerType.imageClick:
        return ImageClickWidget(
          question: question,
          locked: locked,
          answerState: answerState,
          onAnswered: onAnswered,
        );
      case AnswerType.flashcard:
        return FlashcardWidget(
          question: question,
          locked: locked,
          onAnswered: onAnswered,
          spacedRepetitionMode: spacedRepetitionMode,
        );
      case AnswerType.sorting:
        return SortingWidget(
          question: question,
          locked: locked,
          answerState: answerState,
          onAnswered: onAnswered,
        );
    }
  }
}