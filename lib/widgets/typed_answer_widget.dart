import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';

class TypedAnswerWidget extends StatefulWidget {
  final QuestionData question;
  final Function(bool isCorrect) onAnswered;
  final bool locked;

  const TypedAnswerWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.locked,
  });

  @override
  State<TypedAnswerWidget> createState() =>
      _TypedAnswerWidgetState();
}

class _TypedAnswerWidgetState extends State<TypedAnswerWidget> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;

  bool answered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Request focus after the widget is built
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
    if (widget.locked || answered) return;

    final input = _controller.text;
    final isCorrect =
    widget.question.typedAnswerConfig!.isCorrect(input);

    setState(() {
      answered = true;
    });

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // If screen is wide (desktop/tablet)
        final contentWidth = maxWidth > 800
            ? maxWidth * 0.5   // 50% width on large screens
            : maxWidth;        // Full width on small screens

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !widget.locked,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Your Answer",
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: widget.locked ? null : _submit,
                    child: const Text("Submit"),
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