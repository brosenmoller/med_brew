import 'package:flutter/material.dart';

class ImageClickConfig {
  final Rect correctArea;

  ImageClickConfig({
    required this.correctArea,
  });

  bool isCorrect(Offset tapPosition) {
    return correctArea.contains(tapPosition);
  }

  factory ImageClickConfig.fromJson(Map<String, dynamic> json) {
    final area = json['correctArea'];
    return ImageClickConfig(
      correctArea: Rect.fromLTRB(
        (area['left'] as num).toDouble(),
        (area['top'] as num).toDouble(),
        (area['right'] as num).toDouble(),
        (area['bottom'] as num).toDouble(),
      ),
    );
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

  factory MultipleChoiceConfig.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceConfig(
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] as int,
      scrambleOptions: json['scrambleOptions'] as bool? ?? true,
    );
  }
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

  factory TypedAnswerConfig.fromJson(Map<String, dynamic> json) {
    return TypedAnswerConfig(
      acceptedAnswers: List<String>.from(json['acceptedAnswers'] ?? []),
    );
  }
}