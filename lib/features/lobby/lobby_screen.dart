import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/room_model.dart';
import '../../data/services/room_service.dart';
import '../game/game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _isNavigating = false;
  int _selectedRounds = 3;

  Stream<List<PlayerModel>> _getPlayers() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('players')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).snapshots(),
      builder: (context, roomSnap) {
        if (roomSnap.hasData && roomSnap.data!.exists) {
          var roomData = roomSnap.data!.data() as Map<String, dynamic>;
          
          if (roomData['status'] == 'intermission' && !_isNavigating) {
            _isNavigating = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(roomCode: widget.roomCode, isHost: widget.isHost),
                ),
              );
            });
          }

          _selectedRounds = roomData['maxRounds'] ?? 3;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('SALON D\'ATTENTE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('CODE DU SALON',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        widget.roomCode,
                        style: const TextStyle(
                            fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // ROUNDS SELECTION (HOST ONLY)
                if (widget.isHost)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nombre de manches', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            _roundButton(3),
                            _roundButton(5),
                            _roundButton(10),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nombre de manches', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$_selectedRounds',
                            style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'JOUEURS PRÊTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<List<PlayerModel>>(
                    stream: _getPlayers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      List<PlayerModel> players = snapshot.data!;

                      return ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          PlayerModel player = players[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.2),
                                child: Text(player.pseudo[0].toUpperCase(),
                                    style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
                              ),
                              title: Text(player.pseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: player.isHost
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                      ),
                                      child: const Text('HÔTE',
                                          style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                if (widget.isHost)
                  ElevatedButton(
                    onPressed: () => RoomService().startGame(widget.roomCode, maxRounds: _selectedRounds),
                    child: const Text('LANCER LA PARTIE'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      "En attente du lancement par l'hôte...",
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roundButton(int value) {
    bool isSelected = _selectedRounds == value;
    return GestureDetector(
      onTap: () => RoomService().updateMaxRounds(widget.roomCode, value),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C4DFF) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
