import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/services/room_service.dart';
import '../lobby/lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roomCodeController = TextEditingController();
  final _roomService = RoomService();
  bool _isLoading = false;

  // Récupère les données Firestore de l'utilisateur connecté
  Stream<UserModel> _getUserProfile() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data() ?? {}));
  }

  void _createRoom(UserModel user) async {
    setState(() => _isLoading = true);
    String? roomCode = await _roomService.createRoom(
      hostUid: user.uid,
      hostPseudo: user.pseudo,
    );
    setState(() => _isLoading = false);

    if (roomCode != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(roomCode: roomCode, isHost: true),
        ),
      );
    }
  }

  void _joinRoom(UserModel user) async {
    String code = _roomCodeController.text.trim().toUpperCase();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le code doit contenir 4 lettres')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error = await _roomService.joinRoom(
      roomCode: code,
      uid: user.uid,
      pseudo: user.pseudo,
    );
    setState(() => _isLoading = false);

    if (error == null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(roomCode: code, isHost: false),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: _getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        UserModel user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('KROKI'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.palette, size: 70, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue, ${user.pseudo} !',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score total : ${user.totalScore} pts',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    // Bouton Créer une partie
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _createRoom(user),
                        icon: const Icon(Icons.add_box),
                        label: const Text('Créer une partie', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 24),

                    // Rejoindre une partie avec un code
                    TextField(
                      controller: _roomCodeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Code de salon (ex: ABCD)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _joinRoom(user),
                        icon: const Icon(Icons.login),
                        label: const Text('Rejoindre la partie', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}