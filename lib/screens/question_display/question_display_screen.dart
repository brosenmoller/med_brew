import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:med_brew/models/answer_state.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/screens/question_display/answer_area.dart';
import 'package:med_brew/screens/question_display/continue_button.dart';
import 'package:med_brew/screens/question_display/srs_buttons.dart';

class QuestionDisplayScreen extends StatefulWidget {
  final QuestionData question;
  final bool spacedRepetitionMode;
  final Function(bool wasCorrect, SrsQuality? quality) onContinue;

  const QuestionDisplayScreen({
    super.key,
    required this.question,
    required this.onContinue,
    this.spacedRepetitionMode = false,
  });

  @override
  State<QuestionDisplayScreen> createState() => _QuestionDisplayScreenState();
}

class _QuestionDisplayScreenState extends State<QuestionDisplayScreen>
    with SingleTickerProviderStateMixin {
  AnswerState answerState = AnswerState.unanswered;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleAnswer(bool isCorrect) {
    setState(() {
      answerState = isCorrect ? AnswerState.correct : AnswerState.incorrect;
    });

    if (!isCorrect) {
      _shakeController.forward(from: 0);
    } else {
      _confettiController.play();
    }

    if (widget.spacedRepetitionMode && isCorrect) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _showSrsBottomSheet();
      });
    }
  }

  void _showSrsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: SrsButtons(
            question: widget.question,
            onAnswered: (quality) {
              Navigator.pop(ctx);
              widget.onContinue(true, quality);
            },
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    final wasCorrect = answerState == AnswerState.correct;
    setState(() {
      answerState = AnswerState.unanswered;
    });
    widget.onContinue(wasCorrect, null);
  }

  @override
  Widget build(BuildContext context) {
    final showContinue = answerState != AnswerState.unanswered &&
        !(widget.spacedRepetitionMode && answerState == AnswerState.correct);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      // No bottomNavigationBar — using a Stack overlay instead so the body
      // constraints never change and nothing jumps when the button appears.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Cap the bottom section at 55% of the *fixed* body height.
          // Because we never resize the body, this value is stable.
          final maxBottomHeight = constraints.maxHeight * 0.55;

          return Stack(
            children: [

              /// MAIN LAYOUT
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

                  /// BOTTOM SECTION — capped, scrollable
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxBottomHeight),
                    child: SafeArea(
                      top: false,
                      // Extra bottom padding reserves space for the overlaid
                      // continue button so it never covers answer options.
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            /// QUESTION TEXT
                            Center(
                              child: AnimatedBuilder(
                                animation: _shakeController,
                                builder: (context, child) {
                                  final offset = _shakeAnimation.value *
                                      (_shakeController.status ==
                                          AnimationStatus.forward
                                          ? 1
                                          : 0);
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

                            /// ANSWER AREA
                            AnswerArea(
                              question: widget.question,
                              locked: answerState != AnswerState.unanswered,
                              answerState: answerState,
                              onAnswered: _handleAnswer,
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),

              /// CONTINUE BUTTON — overlaid at the bottom, never affects layout
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: AnimatedSlide(
                  offset: showContinue ? Offset.zero : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: showContinue ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !showContinue,
                      child: ContinueButton(onContinue: _handleContinue),
                    ),
                  ),
                ),
              ),

              /// CONFETTI OVERLAY
              Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                    ],
                    numberOfParticles: 10,
                    maxBlastForce: 20,
                    minBlastForce: 10,
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}