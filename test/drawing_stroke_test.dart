import 'package:flutter_test/flutter_test.dart';
import 'package:kroki/data/models/drawing_stroke.dart';

void main() {
  group('DrawingStroke', () {
    test('sérialise et désérialise un trait sans perte', () {
      final stroke = DrawingStroke(
        points: [
          DrawingPoint(x: 10, y: 20),
          DrawingPoint(x: 30, y: 40),
        ],
        colorHex: 0xFF00FF00,
        strokeWidth: 8,
        isEraser: true,
      );

      final restored = DrawingStroke.fromMap(stroke.toMap());

      expect(restored.points.length, 2);
      expect(restored.points.first.x, 10);
      expect(restored.points.last.y, 40);
      expect(restored.colorHex, 0xFF00FF00);
      expect(restored.strokeWidth, 8);
      expect(restored.isEraser, isTrue);
    });
  });
}
