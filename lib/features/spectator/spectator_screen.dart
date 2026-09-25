import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/drawing_stroke.dart';
import '../game/widgets/drawing_canvas.dart';

class SpectatorScreen extends ConsumerWidget {
  final String roomCode;
  const SpectatorScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawing = ref.watch(drawingServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text('SPECTATEUR · $roomCode')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('rooms').doc(roomCode).snapshots(),
        builder: (context, room) {
          if (!room.hasData || !room.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = room.data!.data()!;
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(data['status'] == 'ended' ? 'Partie terminée' : 'Partie en cours'),
                subtitle: Text('Manche ${data['currentRound'] ?? 1} · ${data['timeLeft'] ?? 0}s'),
              ),
              Expanded(
                child: StreamBuilder<List<DrawingStroke>>(
                  stream: drawing.getStrokesStream(roomCode),
                  builder: (context, snapshot) => Semantics(
                    label: 'Toile observée en lecture seule',
                    child: DrawingCanvas(strokes: snapshot.data ?? const [], isDrawer: false),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
