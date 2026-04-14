import 'package:flutter/material.dart';

enum HighlightShapeType { rect, circle }

class HighlightShape {
  /// For rect: top-left corner; for circle: top-left of bounding box.
  /// Normalized 0.0–1.0 relative to image dimensions.
  final Offset p1;

  /// For rect: bottom-right corner; for circle: bottom-right of bounding box.
  /// Normalized 0.0–1.0 relative to image dimensions.
  final Offset p2;

  final HighlightShapeType type;

  /// ARGB color value (e.g. Colors.red.value).
  final int colorValue;

  const HighlightShape({
    required this.type,
    required this.p1,
    required this.p2,
    required this.colorValue,
  });

  factory HighlightShape.fromJson(Map<String, dynamic> json) {
    return HighlightShape(
      type: json['type'] == 'circle'
          ? HighlightShapeType.circle
          : HighlightShapeType.rect,
      p1: Offset(
        (json['p1x'] as num).toDouble(),
        (json['p1y'] as num).toDouble(),
      ),
      p2: Offset(
        (json['p2x'] as num).toDouble(),
        (json['p2y'] as num).toDouble(),
      ),
      colorValue: json['color'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type == HighlightShapeType.circle ? 'circle' : 'rect',
        'p1x': p1.dx,
        'p1y': p1.dy,
        'p2x': p2.dx,
        'p2y': p2.dy,
        'color': colorValue,
      };
}

class OcclusionData {
  /// List of polygons. Each polygon is a list of normalized (0.0–1.0) points.
  final List<List<Offset>> hiddenAreas;

  /// Highlight shapes drawn on top of the image (always visible).
  final List<HighlightShape> highlights;

  const OcclusionData({
    required this.hiddenAreas,
    required this.highlights,
  });

  bool get isEmpty => hiddenAreas.isEmpty && highlights.isEmpty;

  factory OcclusionData.fromJson(Map<String, dynamic> json) {
    final areas = (json['hiddenAreas'] as List<dynamic>? ?? []).map((polygon) {
      return (polygon as List<dynamic>)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList();
    }).toList();

    final shapes = (json['highlights'] as List<dynamic>? ?? [])
        .map((h) => HighlightShape.fromJson(h as Map<String, dynamic>))
        .toList();

    return OcclusionData(hiddenAreas: areas, highlights: shapes);
  }

  Map<String, dynamic> toJson() => {
        'hiddenAreas': hiddenAreas
            .map((polygon) =>
                polygon.map((p) => {'x': p.dx, 'y': p.dy}).toList())
            .toList(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
      };
}
