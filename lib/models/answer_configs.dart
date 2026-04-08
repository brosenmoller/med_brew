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

  Map<String, dynamic> toJson() => {
    'options': options,
    'correctIndex': correctIndex,
    'scrambleOptions': scrambleOptions,
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
