import 'package:firebase_database/firebase_database.dart';
import '../models/drawing_stroke.dart';

class DrawingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Envoyer un nouveau trait tracé par le dessinateur
  Future<void> sendStroke(String roomCode, DrawingStroke stroke) async {
    final ref = _db.ref('strokes/$roomCode').push();
    await ref.set(stroke.toMap());
  }

  // Écouter les traits arrivant en temps réel
  Stream<List<DrawingStroke>> getStrokesStream(String roomCode) {
    return _db.ref('strokes/$roomCode').onValue.map((event) {
      if (event.snapshot.value == null) return [];

      final value = event.snapshot.value;
      if (value is! Map) return [];

      final data = Map<String, dynamic>.from(value);
      List<DrawingStroke> strokes = [];

      data.forEach((key, val) {
        if (val is Map) {
          strokes.add(DrawingStroke.fromMap(Map<String, dynamic>.from(val)));
        }
      });

      return strokes;
    });
  }

  // Effacer la toile
  Future<void> clearCanvas(String roomCode) async {
    await _db.ref('strokes/$roomCode').remove();
  }
}