import 'package:flutter_test/flutter_test.dart';
import 'package:kroki/data/models/drawing_stroke.dart';
import 'package:kroki/data/services/drawing_recognizer.dart';

void main() {
  test('évalue une forme suffisamment large', () {
    final points = List.generate(12, (index) => DrawingPoint(x: index.toDouble(), y: index.toDouble()));
    final result = DrawingRecognizer().recognize([DrawingStroke(points: points)], 'forme');
    expect(result.confidence, greaterThan(0));
  });
}
