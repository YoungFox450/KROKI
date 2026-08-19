import 'package:flutter/material.dart';
import '../../../data/models/drawing_stroke.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawingStroke> strokes;
  final bool isDrawer;
  final Function(DrawingStroke)? onStrokeCompleted;
  final Color selectedColor;
  final double selectedWidth;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.isDrawer,
    this.onStrokeCompleted,
    this.selectedColor = Colors.white,
    this.selectedWidth = 4.0,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<DrawingPoint> currentPoints = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.isDrawer
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
      onPanUpdate: widget.isDrawer
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
      onPanEnd: widget.isDrawer
          ? (details) {
              if (currentPoints.isNotEmpty) {
                final stroke = DrawingStroke(
                  points: List.from(currentPoints),
                  colorHex: widget.selectedColor.value,
                  strokeWidth: widget.selectedWidth,
                );
                widget.onStrokeCompleted?.call(stroke);
                setState(() => currentPoints.clear());
              }
            }
          : null,
      child: CustomPaint(
        painter: CanvasPainter(
          strokes: widget.strokes,
          currentPoints: currentPoints,
          currentColor: widget.selectedColor,
          currentWidth: widget.selectedWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingPoint> currentPoints;
  final Color currentColor;
  final double currentWidth;

  CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les traits validés reçus du serveur
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.colorHex)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
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
        ..color = currentColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = currentWidth;

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
