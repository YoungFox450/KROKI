import 'package:flutter/material.dart';
import '../../data/models/drawing_stroke.dart';
import '../../data/services/drawing_recognizer.dart';
import '../game/widgets/drawing_canvas.dart';

class SoloTrainingScreen extends StatefulWidget {
  const SoloTrainingScreen({super.key});

  @override
  State<SoloTrainingScreen> createState() => _SoloTrainingScreenState();
}

class _SoloTrainingScreenState extends State<SoloTrainingScreen> {
  final _recognizer = DrawingRecognizer();
  final _strokes = <DrawingStroke>[];
  final _target = 'une forme ronde';
  String _feedback = 'Dessine une forme dans la toile';

  void _evaluate(DrawingStroke stroke) {
    setState(() {
      _strokes.add(stroke);
      final result = _recognizer.recognize(_strokes, _target);
      _feedback = '${result.label} · ${(result.confidence * 100).round()}%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ENTRAÎNEMENT SOLO')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Défi du jour', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_target, style: const TextStyle(fontSize: 22)),
              Text(_feedback, semanticsLabel: 'Résultat : $_feedback'),
            ]),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(24)),
              child: DrawingCanvas(
                strokes: _strokes,
                isDrawer: true,
                onStrokeCompleted: _evaluate,
                selectedColor: Theme.of(context).colorScheme.primary,
                selectedWidth: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
