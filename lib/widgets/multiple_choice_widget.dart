import 'dart:math';
import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:flutter/foundation.dart';

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

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 200,
                  maxWidth: screenWidth * 0.9,
                ),
                child: ElevatedButton(
                  onPressed: widget.locked
                      ? null
                      : () => _selectOption(index),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                  ),
                  child: Text(
                    options[index],
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

}