import 'package:flutter/material.dart';
import '../../../data/models/drawing_stroke.dart';

class DrawingCanvas extends StatelessWidget {
  final List<DrawingStroke> strokes;
  final bool isDrawer;
  final Function(DrawingStroke)? onStrokeCompleted;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.isDrawer,
    this.onStrokeCompleted,
  });

  @override
  Widget build(BuildContext context) {
    List<DrawingPoint> currentPoints = [];

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onPanStart: isDrawer
              ? (details) {
            setState(() {
              currentPoints = [
                DrawingPoint(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                )
              ];
            });
          }
              : null,
          onPanUpdate: isDrawer
              ? (details) {
            setState(() {
              currentPoints.add(
                DrawingPoint(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                ),
              );
            });
          }
              : null,
          onPanEnd: isDrawer
              ? (details) {
            if (currentPoints.isNotEmpty) {
              final stroke = DrawingStroke(
                points: List.from(currentPoints),
                colorHex: Colors.deepPurpleAccent.value,
                strokeWidth: 4.0,
              );
              onStrokeCompleted?.call(stroke);
              setState(() => currentPoints.clear());
            }
          }
              : null,
          child: CustomPaint(
            painter: CanvasPainter(
              strokes: strokes,
              currentPoints: currentPoints,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingPoint> currentPoints;

  CanvasPainter({required this.strokes, required this.currentPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les traits validés reçus du serveur
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.colorHex)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.strokeWidth;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          Offset(stroke.points[i].x, stroke.points[i].y),
          Offset(stroke.points[i + 1].x, stroke.points[i + 1].y),
          paint,
        );
      }
    }

    // Dessiner le trait en cours de tracé par le dessinateur
    if (currentPoints.length > 1) {
      final paint = Paint()
        ..color = Colors.deepPurpleAccent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.0;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(
          Offset(currentPoints[i].x, currentPoints[i].y),
          Offset(currentPoints[i + 1].x, currentPoints[i + 1].y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}