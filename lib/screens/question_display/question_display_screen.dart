import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/widgets/multiple_choice_widget.dart';
import 'package:med_brew/widgets/typed_answer_widget.dart';
import 'package:med_brew/widgets/image_click_widget.dart';
import 'package:confetti/confetti.dart';

enum AnswerState {
  unanswered,
  correct,
  incorrect,
}

class QuestionDisplayScreen extends StatefulWidget {
  final QuestionData question;
  final bool spacedRepetitionMode;
  final Function(bool wasCorrect) onContinue;

  const QuestionDisplayScreen({
    super.key,
    required this.question,
    required this.onContinue,
    this.spacedRepetitionMode = false,
  });

  @override
  State<QuestionDisplayScreen> createState() =>
      _QuestionDisplayScreenState();
}

class _QuestionDisplayScreenState extends State<QuestionDisplayScreen> with SingleTickerProviderStateMixin {
  AnswerState answerState = AnswerState.unanswered;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;

  int questionKey = 0;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleAnswer(bool isCorrect) {
    setState(() {
      answerState =
      isCorrect ? AnswerState.correct : AnswerState.incorrect;

      if (!isCorrect) {
        _shakeController.forward(from: 0); // shake wrong answer
      } else {
        _confettiController.play(); // 🎉 trigger confetti
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              final offsetAnim = Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(
                position: offsetAnim,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _buildQuestionContent(key: ValueKey<int>(questionKey)),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent({required Key key}) {
    final question = widget.question;

    return Padding(
      key: key,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // IMAGE AT TOP
          if (question.imagePath != null)
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Image.asset(
                question.imagePath!,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 16),

          // QUESTION TEXT WITH SHAKE
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              double offset =
                  _shakeAnimation.value * (_shakeController.status == AnimationStatus.forward ? 1 : 0);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                question.questionVariants.first,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // DYNAMIC ANSWER AREA
          Expanded(
            child: _buildAnswerWidget(question),
          ),

          // FEEDBACK BOX
          AnimatedOpacity(
            opacity: answerState == AnswerState.unanswered ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            child: answerState != AnswerState.unanswered
                ? _buildFeedbackBox()
                : const SizedBox.shrink(),
          ),

          // CONTINUE / SRS BUTTONS
          AnimatedScale(
            scale: answerState == AnswerState.unanswered ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            child: answerState != AnswerState.unanswered
                ? widget.spacedRepetitionMode && answerState == AnswerState.correct
                ? _buildSrsButtons()
                : _buildContinueButton()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(QuestionData question) {
    switch (question.answerType) {
      case AnswerType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          onAnswered: _handleAnswer,
          locked: answerState != AnswerState.unanswered,
        );

      case AnswerType.typed:
        return TypedAnswerWidget(
          question: question,
          onAnswered: _handleAnswer,
          locked: answerState != AnswerState.unanswered,
        );

      case AnswerType.imageClick:
        return ImageClickWidget(
          question: question,
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
            // Reset for next question animation
            setState(() {
              answerState = AnswerState.unanswered;
              questionKey++; // triggers AnimatedSwitcher
            });
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
    final question = widget.question;

    switch (question.answerType) {
      case AnswerType.multipleChoice:
        final correctIndex = question.multipleChoiceConfig!.correctIndex;
        return question.multipleChoiceConfig!.options[correctIndex];

      case AnswerType.typed:
        return question.typedAnswerConfig!.acceptedAnswers.join(", ");

      case AnswerType.imageClick:
        return "Correct area" ; // optionally replace with more detailed info later
    }
  }
}