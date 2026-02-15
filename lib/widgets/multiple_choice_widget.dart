import 'dart:math';
import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final QuestionData question;
  final Function(bool isCorrect) onAnswered;
  final bool locked;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.locked,
  });

  @override
  State<MultipleChoiceWidget> createState() =>
      _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState
    extends State<MultipleChoiceWidget> {
  late List<String> options;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();

    final config = widget.question.multipleChoiceConfig!;
    options = List.from(config.options);

    if (config.scrambleOptions) {
      options.shuffle(Random());
    }
  }

  void _selectOption(int index) {
    if (widget.locked || selectedIndex != null) return;

    setState(() {
      selectedIndex = index;
    });

    final correctAnswer =
    widget.question.multipleChoiceConfig!.options[
    widget.question.multipleChoiceConfig!.correctIndex];

    final isCorrect = options[index] == correctAnswer;

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ElevatedButton(
            onPressed: widget.locked
                ? null
                : () => _selectOption(index),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: Text(options[index]),
          ),
        );
      },
    );
  }
}