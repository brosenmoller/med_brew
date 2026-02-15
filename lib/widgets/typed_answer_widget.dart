import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';

class TypedAnswerWidget extends StatefulWidget {
  final QuestionData card;
  final Function(bool isCorrect) onAnswered;
  final bool locked;

  const TypedAnswerWidget({
    super.key,
    required this.card,
    required this.onAnswered,
    required this.locked,
  });

  @override
  State<TypedAnswerWidget> createState() =>
      _TypedAnswerWidgetState();
}

class _TypedAnswerWidgetState extends State<TypedAnswerWidget> {
  final TextEditingController _controller =
  TextEditingController();

  bool answered = false;

  void _submit() {
    if (widget.locked || answered) return;

    final input = _controller.text;
    final isCorrect =
    widget.card.typedAnswerConfig!.isCorrect(input);

    setState(() {
      answered = true;
    });

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            enabled: !widget.locked,
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
    );
  }
}