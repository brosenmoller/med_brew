import 'package:flutter/material.dart';

class ImageClickConfig {
  /// List of polygons. Each polygon is a list of normalized (0.0–1.0) points.
  final List<List<Offset>> correctAreas;

  ImageClickConfig({required this.correctAreas});

  bool isCorrect(Offset tapPosition) {
    return correctAreas.any(
      (polygon) => polygon.length >= 3 && _containsPoint(polygon, tapPosition),
    );
  }

  /// Ray-casting point-in-polygon test (normalized coordinates).
  static bool _containsPoint(List<Offset> polygon, Offset point) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  factory ImageClickConfig.fromJson(Map<String, dynamic> json) {
    // Backward compatibility: old format stored a single rect as 'correctArea'.
    if (json.containsKey('correctArea') && !json.containsKey('correctAreas')) {
      final area = json['correctArea'] as Map<String, dynamic>;
      final l = (area['left'] as num).toDouble();
      final t = (area['top'] as num).toDouble();
      final r = (area['right'] as num).toDouble();
      final b = (area['bottom'] as num).toDouble();
      return ImageClickConfig(correctAreas: [
        [Offset(l, t), Offset(r, t), Offset(r, b), Offset(l, b)],
      ]);
    }

    final areas = json['correctAreas'] as List<dynamic>;
    return ImageClickConfig(
      correctAreas: areas.map((polygon) {
        return (polygon as List<dynamic>)
            .map((p) => Offset(
                  (p['x'] as num).toDouble(),
                  (p['y'] as num).toDouble(),
                ))
            .toList();
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'correctAreas': correctAreas
            .map((polygon) =>
                polygon.map((p) => {'x': p.dx, 'y': p.dy}).toList())
            .toList(),
      };
}

class FlashcardConfig {
  final String? frontText;
  final String? frontImagePath;
  final String? backText;
  final String? backImagePath;
  final bool randomizeSides;

  FlashcardConfig({
    this.frontText,
    this.frontImagePath,
    this.backText,
    this.backImagePath,
    this.randomizeSides = false,
  });

  factory FlashcardConfig.fromJson(Map<String, dynamic> json) {
    return FlashcardConfig(
      frontText: json['frontText'] as String?,
      frontImagePath: json['frontImagePath'] as String?,
      backText: json['backText'] as String?,
      backImagePath: json['backImagePath'] as String?,
      randomizeSides: json['randomizeSides'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (frontText != null) map['frontText'] = frontText;
    if (frontImagePath != null) map['frontImagePath'] = frontImagePath;
    if (backText != null) map['backText'] = backText;
    if (backImagePath != null) map['backImagePath'] = backImagePath;
    if (randomizeSides) map['randomizeSides'] = true;
    return map;
  }
}

class MultipleChoiceConfig {
  final List<String> options;
  final List<int> correctIndices;
  final bool scrambleOptions;
  final bool multipleCorrect;
  final bool showCorrectCount;

  MultipleChoiceConfig({
    required this.options,
    required this.correctIndices,
    this.scrambleOptions = true,
    this.multipleCorrect = false,
    this.showCorrectCount = false,
  });

  /// Backward-compat accessor for code that still reads a single index.
  int get correctIndex => correctIndices.isNotEmpty ? correctIndices.first : 0;

  factory MultipleChoiceConfig.fromJson(Map<String, dynamic> json) {
    List<int> indices;
    if (json.containsKey('correctIndices')) {
      indices = List<int>.from(json['correctIndices'] as List);
    } else if (json.containsKey('correctIndex')) {
      indices = [json['correctIndex'] as int];
    } else {
      indices = [0];
    }
    return MultipleChoiceConfig(
      options: List<String>.from(json['options'] ?? []),
      correctIndices: indices,
      scrambleOptions: json['scrambleOptions'] as bool? ?? true,
      multipleCorrect: json['multipleCorrect'] as bool? ?? false,
      showCorrectCount: json['showCorrectCount'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'options': options,
    'correctIndices': correctIndices,
    'scrambleOptions': scrambleOptions,
    if (multipleCorrect) 'multipleCorrect': true,
    if (showCorrectCount) 'showCorrectCount': true,
  };
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

  Map<String, dynamic> toJson() => {
    'acceptedAnswers': acceptedAnswers,
  };
}
