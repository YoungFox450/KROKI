import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/room_model.dart';
import '../../data/services/room_service.dart';
import '../game/game_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String roomCode;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  Stream<List<PlayerModel>> _getPlayers() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList());
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements de statut de la salle
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(roomCode).snapshots(),
      builder: (context, roomSnap) {
        if (roomSnap.hasData && roomSnap.data!.exists) {
          var roomData = roomSnap.data!.data() as Map<String, dynamic>;
          
          // Si l'hôte a lancé la partie, redirection pour TOUS les joueurs !
          if (roomData['status'] == 'playing') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(roomCode: roomCode, isHost: isHost),
                ),
              );
            });
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Salon : $roomCode'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurpleAccent),
                  ),
                  child: Column(
                    children: [
                      const Text('Code de la salle', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        roomCode,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Joueurs dans la salle :',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<List<PlayerModel>>(
                    stream: _getPlayers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<PlayerModel> players = snapshot.data!;

                      return ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          PlayerModel player = players[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurpleAccent,
                                child: Text(player.pseudo[0].toUpperCase()),
                              ),
                              title: Text(player.pseudo),
                              trailing: player.isHost
                                  ? const Chip(
                                      label: Text('Hôte', style: TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.amber,
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                if (isHost)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => RoomService().startGame(roomCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Lancer la partie', style: TextStyle(fontSize: 18)),
                    ),
                  )
                else
                  const Text(
                    "En attente de l'hôte pour démarrer...",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
