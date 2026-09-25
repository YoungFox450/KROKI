import '../models/drawing_stroke.dart';

class RecognitionResult {
  final String label;
  final double confidence;
  const RecognitionResult(this.label, this.confidence);
}

/// Reconnaissance locale légère en attendant un modèle embarqué.
class DrawingRecognizer {
  RecognitionResult recognize(List<DrawingStroke> strokes, String target) {
    final points = strokes.expand((stroke) => stroke.points).toList();
    if (points.length < 8) return const RecognitionResult('Continue à dessiner', 0.1);
    final minX = points.map((point) => point.x).reduce((a, b) => a < b ? a : b);
    final maxX = points.map((point) => point.x).reduce((a, b) => a > b ? a : b);
    final minY = points.map((point) => point.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((point) => point.y).reduce((a, b) => a > b ? a : b);
    final width = maxX - minX;
    final height = maxY - minY;
    if (width <= 0 || height <= 0) return const RecognitionResult('Forme incomplète', 0.2);
    final ratio = width / height;
    return RecognitionResult(target, (1 - (ratio - 1).abs()).clamp(0.0, 1.0).toDouble());
  }
}
