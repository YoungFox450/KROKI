import 'package:flutter/material.dart';
import '../../data/models/drawing_stroke.dart';
import '../../data/services/drawing_service.dart';
import '../game/widgets/drawing_canvas.dart';

class ReplayScreen extends StatefulWidget {
  final String roomCode;
  const ReplayScreen({super.key, required this.roomCode});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  final _service = DrawingService();
  List<DrawingStroke> _strokes = [];
  int _visible = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final strokes = await _service.getStrokesOnce(widget.roomCode);
    if (!mounted) return;
    setState(() {
      _strokes = strokes;
      _loading = false;
    });
  }

  void _togglePlayback() {
    if (_visible >= _strokes.length) {
      setState(() => _visible = 0);
      return;
    }
    setState(() => _visible++);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _visible < _strokes.length) _togglePlayback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REPLAY DU DESSIN')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Replay du dessin de la salle ${widget.roomCode}',
                    child: DrawingCanvas(
                      strokes: _strokes.take(_visible).toList(),
                      isDrawer: false,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: _strokes.isEmpty ? null : _togglePlayback,
                    icon: Icon(_visible >= _strokes.length ? Icons.replay : Icons.play_arrow),
                    label: Text(_visible >= _strokes.length ? 'Rejouer' : 'Lire le replay'),
                  ),
                ),
              ],
            ),
    );
  }
}
