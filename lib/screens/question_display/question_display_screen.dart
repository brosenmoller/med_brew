import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/services/srs_service.dart';
import 'answer_area.dart';
import 'feedback_box.dart';
import 'continue_button.dart';
import 'srs_buttons.dart';

enum AnswerState { unanswered, correct, incorrect }

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
  State<QuestionDisplayScreen> createState() => _QuestionDisplayScreenState();
}

class _QuestionDisplayScreenState extends State<QuestionDisplayScreen> with SingleTickerProviderStateMixin {
  bool? _wasCorrect;
  AnswerState answerState = AnswerState.unanswered;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final ConfettiController _confettiController;
  int questionKey = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleAnswer(bool isCorrect) {
    setState(() {
      _wasCorrect = isCorrect; // store correctness
      answerState = isCorrect ? AnswerState.correct : AnswerState.incorrect;

      if (!isCorrect) {
        _shakeController.forward(from: 0);
      } else {
        _confettiController.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Column(
            children: [

              /// IMAGE AREA
              Expanded(
                child: widget.question.imagePath != null
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.asset(
                    widget.question.imagePath!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              /// BOTTOM CONTENT
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      const SizedBox(height: 16),

                      /// QUESTION
                      Center(
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            double offset = _shakeAnimation.value *
                                (_shakeController.status == AnimationStatus.forward ? 1 : 0);

                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: Text(
                            widget.question.questionVariants.first,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ANSWERS
                      AnswerArea(
                        question: widget.question,
                        locked:
                        answerState != AnswerState.unanswered,
                        onAnswered: _handleAnswer,
                      ),

                      /// FEEDBACK
                      AnimatedOpacity(
                        opacity:
                        answerState == AnswerState.unanswered
                            ? 0
                            : 1,
                        duration:
                        const Duration(milliseconds: 400),
                        child: answerState !=
                            AnswerState.unanswered
                            ? FeedbackBox(
                          answerState: answerState,
                          question: widget.question,
                        )
                            : const SizedBox.shrink(),
                      ),

                      /// CONTINUE / SRS
                      AnimatedScale(
                        scale:
                        answerState == AnswerState.unanswered
                            ? 0
                            : 1,
                        duration:
                        const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        child: answerState !=
                            AnswerState.unanswered
                            ? widget.spacedRepetitionMode &&
                            answerState ==
                                AnswerState.correct
                            ? SrsButtons(
                          question: widget.question,
                          onAnswered:
                              (quality) async {
                            final wasCorrect =
                                _wasCorrect ?? true;

                            await SrsService()
                                .updateAfterAnswer(
                                widget.question,
                                quality);

                            if (!context.mounted)
                              return;

                            Navigator.of(context)
                                .pop(wasCorrect);
                          },
                        )
                            : ContinueButton(
                          onContinue: () {
                            final wasCorrect =
                                answerState ==
                                    AnswerState
                                        .correct;

                            setState(() {
                              answerState =
                                  AnswerState
                                      .unanswered;
                              questionKey++;
                            });

                            widget.onContinue(
                                wasCorrect);
                          },
                        )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// CONFETTI OVERLAY
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality:
                BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange
                ],
                numberOfParticles: 10,
                maxBlastForce: 20,
                minBlastForce: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}