import 'package:flutter/material.dart';
import 'package:med_brew/models/answer_state.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/widgets/question_image.dart';

class TypedAnswerWidget extends StatefulWidget {
  final QuestionData question;
  final Function(bool isCorrect) onAnswered;
  final bool locked;
  final AnswerState answerState;

  const TypedAnswerWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.locked,
    required this.answerState,
  });

  @override
  State<TypedAnswerWidget> createState() => _TypedAnswerWidgetState();
}

class _TypedAnswerWidgetState extends State<TypedAnswerWidget> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.locked || _submitted) return;
    final isCorrect =
    widget.question.typedAnswerConfig!.isCorrect(_controller.text);
    setState(() => _submitted = true);
    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final answered = widget.answerState != AnswerState.unanswered;
    final isCorrect = widget.answerState == AnswerState.correct;
    final feedbackColor = isCorrect ? Colors.green.shade600 : Colors.red.shade600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth > 800
            ? constraints.maxWidth * 0.5
            : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.question.imagePath != null) ...[
                    QuestionImage(path: widget.question.imagePath!),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.locked,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Your Answer',
                      border: const OutlineInputBorder(),
                      enabledBorder: answered
                          ? OutlineInputBorder(
                        borderSide:
                        BorderSide(color: feedbackColor, width: 2),
                      )
                          : null,
                      disabledBorder: answered
                          ? OutlineInputBorder(
                        borderSide:
                        BorderSide(color: feedbackColor, width: 2),
                      )
                          : null,
                      labelStyle:
                      answered ? TextStyle(color: feedbackColor) : null,
                      suffixIcon: answered
                          ? Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: feedbackColor,
                      )
                          : null,
                    ),
                  ),
                  if (answered && !isCorrect) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Correct answer: '
                              '${widget.question.typedAnswerConfig!.acceptedAnswers.join(' / ')}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: widget.locked ? null : _submit,
                    child: const Text('Submit'),
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