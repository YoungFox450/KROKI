import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/services/room_service.dart';
import '../../data/services/social_service.dart';
import '../lobby/lobby_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../social/social_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _roomCodeController = TextEditingController();
  final _roomService = RoomService();
  final SocialService _socialService = SocialService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socialService.setupPresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socialService.updatePresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _socialService.updatePresence(true);
    } else {
      _socialService.updatePresence(false);
    }
  }

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
        const SnackBar(
          content: Text('Le code doit contenir 4 lettres'),
          behavior: SnackBarBehavior.floating,
        ),
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
        SnackBar(
          content: Text(error!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
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
          body: Stack(
            children: [
              // BACKGROUND GRADIENT
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.7, -0.6),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF7C4DFF).withOpacity(0.1),
                        const Color(0xFF121212),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.2),
                                  child: Text(user.pseudo[0].toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bonjour,',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                    ),
                                    Text(
                                      user.pseudo,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                            icon: const Icon(Icons.settings_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C4DFF).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VOTRE SCORE TOTAL',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${user.totalScore} PTS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'PRÊT À JOUER ?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildMenuCard(
                                context,
                                title: 'Créer un salon',
                                subtitle: 'Invitez vos amis et jouez ensemble',
                                icon: Icons.add_rounded,
                                color: const Color(0xFF7C4DFF),
                                onTap: () => _createRoom(user),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.vpn_key_outlined, color: Colors.amberAccent),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Rejoindre un salon',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: TextField(
                                              controller: _roomCodeController,
                                              textCapitalization: TextCapitalization.characters,
                                              maxLength: 4,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 5),
                                              decoration: InputDecoration(
                                                hintText: 'CODE',
                                                counterText: "",
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                hintStyle: TextStyle(
                                                  color: Colors.white.withOpacity(0.2),
                                                  letterSpacing: 0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          height: 56,
                                          width: 80,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : () => _joinRoom(user),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: const Icon(Icons.arrow_forward_rounded),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildMenuCard(
                                context,
                                title: 'Amis & Chat',
                                subtitle: 'Gérez vos contacts et discutez',
                                icon: Icons.people_alt_rounded,
                                color: Colors.lightBlueAccent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SocialScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildMenuCard(
                                context,
                                title: 'Classement',
                                subtitle: 'Découvrez les meilleurs dessinateurs',
                                icon: Icons.leaderboard_rounded,
                                color: Colors.amberAccent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
