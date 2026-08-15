import 'package:flutter/material.dart';

class DrawingPoint {
  final double x;
  final double y;

  DrawingPoint({required this.x, required this.y});

  Map<String, double> toMap() => {'x': x, 'y': y};

  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final int colorHex;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    this.colorHex = 0xFFFFFFFF, // Blanc par défaut
    this.strokeWidth = 4.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => p.toMap()).toList(),
      'color': colorHex,
      'width': strokeWidth,
    };
  }

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    var pointsList = (map['points'] as List? ?? [])
        .map((p) => DrawingPoint.fromMap(Map<String, dynamic>.from(p)))
        .toList();

    return DrawingStroke(
      points: pointsList,
      colorHex: map['color'] ?? 0xFFFFFFFF,
      strokeWidth: (map['width'] as num? ?? 4.0).toDouble(),
    );
  }
}