import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/room_model.dart';
import '../../core/providers/service_providers.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isNavigating = false;
  int _selectedRounds = 3;
  String _selectedLocale = 'fr';
  String _selectedTheme = 'mix';
  String _selectedMode = 'classic';

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
              context.go('/game/${widget.roomCode}?host=${widget.isHost}');
            });
          }

          _selectedRounds = roomData['maxRounds'] ?? 3;
          _selectedLocale = roomData['wordLocale'] ?? 'fr';
          _selectedTheme = roomData['wordTheme'] ?? 'mix';
          _selectedMode = roomData['gameMode'] ?? 'classic';
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

                const SizedBox(height: 12),
                _buildWordPackPicker(),
                const SizedBox(height: 12),
                _buildGameModePicker(),
                
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
                  onPressed: () => ref.read(roomServiceProvider).startGame(widget.roomCode, maxRounds: _selectedRounds),
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
      onTap: () => ref.read(roomServiceProvider).updateMaxRounds(widget.roomCode, value),
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

  Widget _buildWordPackPicker() {
    return Semantics(
      container: true,
      label: 'Pack de mots',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Expanded(child: Text('Mots de la partie', style: TextStyle(fontWeight: FontWeight.bold))),
            if (widget.isHost) ...[
              DropdownButton<String>(
                value: _selectedLocale,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text('FR')),
                  DropdownMenuItem(value: 'ln', child: Text('LIN')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedLocale = value);
                  ref.read(roomServiceProvider).updateWordPack(
                        widget.roomCode,
                        locale: value,
                        theme: _selectedTheme,
                      );
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedTheme,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'mix', child: Text('Mix')),
                  DropdownMenuItem(value: 'kin', child: Text('Kinshasa')),
                  DropdownMenuItem(value: 'lingala', child: Text('Lingala')),
                  DropdownMenuItem(value: 'animaux', child: Text('Animaux')),
                  DropdownMenuItem(value: 'objets', child: Text('Objets')),
                  DropdownMenuItem(value: 'musique', child: Text('Musique')),
                  DropdownMenuItem(value: 'community', child: Text('Communauté')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedTheme = value);
                  ref.read(roomServiceProvider).updateWordPack(
                        widget.roomCode,
                        locale: _selectedLocale,
                        theme: value,
                      );
                },
              ),
            ] else
              Text('${_selectedLocale.toUpperCase()} · $_selectedTheme'),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModePicker() {
    return Semantics(
      container: true,
      label: 'Mode de jeu',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Expanded(child: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
            if (widget.isHost)
              DropdownButton<String>(
                value: _selectedMode,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'classic', child: Text('Classique')),
                  DropdownMenuItem(value: 'blitz', child: Text('Blitz · 30s')),
                  DropdownMenuItem(value: 'cooperative', child: Text('Coopératif')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedMode = value);
                  ref.read(roomServiceProvider).updateGameMode(widget.roomCode, value);
                },
              )
            else
              Text(_selectedMode),
          ],
        ),
      ),
    );
  }
}
