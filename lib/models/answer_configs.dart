import 'package:flutter/material.dart';

class ImageClickConfig {
  final Rect correctArea;

  ImageClickConfig({
    required this.correctArea,
  });

  bool isCorrect(Offset tapPosition) {
    return correctArea.contains(tapPosition);
  }
}

class MultipleChoiceConfig {
  final List<String> options;
  final int correctIndex;
  final bool scrambleOptions;

  MultipleChoiceConfig({
    required this.options,
    required this.correctIndex,
    this.scrambleOptions = true,
  });
}

class TypedAnswerConfig {
  final List<String> acceptedAnswers;

  TypedAnswerConfig({
    required this.acceptedAnswers,
  });

  bool isCorrect(String input) {
    String normalize(String text) {
      return text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    final normalizedInput = normalize(input);

    return acceptedAnswers
        .map((a) => normalize(a))
        .contains(normalizedInput);
  }
}