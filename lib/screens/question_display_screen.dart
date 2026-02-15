import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/widgets/multiple_choice_widget.dart';
import 'package:med_brew/widgets/typed_answer_widget.dart';
import 'package:med_brew/widgets/image_click_widget.dart';

enum AnswerState {
  unanswered,
  correct,
  incorrect,
}

class QuestionDisplayScreen extends StatefulWidget {
  final QuestionData card;
  final bool spacedRepetitionMode;
  final Function(bool wasCorrect) onContinue;


  const QuestionDisplayScreen({
    super.key,
    required this.card,
    required this.onContinue,
    this.spacedRepetitionMode = false,
  });

  @override
  State<QuestionDisplayScreen> createState() =>
      _QuestionDisplayScreenState();
}

class _QuestionDisplayScreenState extends State<QuestionDisplayScreen> {
  AnswerState answerState = AnswerState.unanswered;

  void _handleAnswer(bool isCorrect) {
    setState(() {
      answerState =
      isCorrect ? AnswerState.correct : AnswerState.incorrect;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // IMAGE AT TOP
          if (card.imagePath != null)
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Image.asset(
                card.imagePath!,
                fit: BoxFit.contain,
              ),
            ),

          const SizedBox(height: 16),

          // QUESTION TEXT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              card.questionVariants.first,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          const SizedBox(height: 20),

          // DYNAMIC ANSWER AREA
          Expanded(
            child: _buildAnswerWidget(card),
          ),

          // FEEDBACK BOX
          if (answerState != AnswerState.unanswered)
            _buildFeedbackBox(),

          // CONTINUE / SRS BUTTONS
          if (answerState != AnswerState.unanswered)
            widget.spacedRepetitionMode && answerState == AnswerState.correct
                ? _buildSrsButtons()
                : _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(QuestionData card) {
    switch (card.answerType) {
      case AnswerType.multipleChoice:
        return MultipleChoiceWidget(
          card: card,
          onAnswered: _handleAnswer,
          locked: answerState != AnswerState.unanswered,
        );

      case AnswerType.typed:
        return TypedAnswerWidget(
          card: card,
          onAnswered: _handleAnswer,
          locked: answerState != AnswerState.unanswered,
        );

      case AnswerType.imageClick:
        return ImageClickWidget(
          card: card,
          onAnswered: _handleAnswer,
          locked: answerState != AnswerState.unanswered,
        );
    }
  }

  Widget _buildFeedbackBox() {
    final isCorrect = answerState == AnswerState.correct;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            isCorrect ? "Correct!" : "Incorrect",
            style: const TextStyle(color: Colors.white, fontSize: 18),
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
    );
  }

  Widget _buildContinueButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: IconButton(
          iconSize: 36,
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            final wasCorrect = answerState == AnswerState.correct;
            widget.onContinue(wasCorrect);
            },
        ),
      ),
    );
  }

  Widget _buildSrsButtons() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _srsButton("Again (10m)", () {}),
          _srsButton("Hard (1d)", () {}),
          _srsButton("Good (3d)", () {}),
          _srsButton("Easy (7d)", () {}),
        ],
      ),
    );
  }

  Widget _srsButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }

  String get correctAnswerText {
    final card = widget.card;

    switch (card.answerType) {
      case AnswerType.multipleChoice:
        final correctIndex = card.multipleChoiceConfig!.correctIndex;
        return card.multipleChoiceConfig!.options[correctIndex];

      case AnswerType.typed:
        return card.typedAnswerConfig!.acceptedAnswers.join(", ");

      case AnswerType.imageClick:
        return "Correct area" ; // optionally replace with more detailed info later
    }
  }
}