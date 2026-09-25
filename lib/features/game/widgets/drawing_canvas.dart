import 'package:flutter/material.dart';
import '../../../data/models/drawing_stroke.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawingStroke> strokes;
  final bool isDrawer;
  final Function(DrawingStroke)? onStrokeCompleted;
  final Color selectedColor;
  final double selectedWidth;
  final bool isEraser;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.isDrawer,
    this.onStrokeCompleted,
    this.selectedColor = Colors.white,
    this.selectedWidth = 4.0,
    this.isEraser = false,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<DrawingPoint> currentPoints = [];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.isDrawer ? 'Zone de dessin active' : 'Dessin des autres joueurs',
      hint: widget.isDrawer ? 'Faites glisser votre doigt pour dessiner' : 'Lecture seule',
      child: GestureDetector(
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
                  isEraser: widget.isEraser,
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
            currentIsEraser: widget.isEraser,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingPoint> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool currentIsEraser;

  CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.currentIsEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    // Dessiner les traits validés reçus du serveur
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.colorHex)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth;
      if (stroke.isEraser) paint.blendMode = BlendMode.clear;

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
      if (currentIsEraser) paint.blendMode = BlendMode.clear;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(
          Offset(currentPoints[i].x, currentPoints[i].y),
          Offset(currentPoints[i + 1].x, currentPoints[i + 1].y),
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}
