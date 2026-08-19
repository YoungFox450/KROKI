import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _pseudoController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pseudoController = TextEditingController(text: widget.user.pseudo);
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  void _updatePseudo() async {
    String newPseudo = _pseudoController.text.trim();
    if (newPseudo.isEmpty || newPseudo == widget.user.pseudo) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'pseudo': newPseudo});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pseudo mis à jour !'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double winRate = widget.user.gamesPlayed > 0 
        ? (widget.user.totalScore / (widget.user.gamesPlayed * 100)) * 100 
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MON PROFIL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: Text(
                      widget.user.pseudo[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF)),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle),
                  child: const Icon(Icons.edit_rounded, size: 20, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // PSEUDO SECTION
            _isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pseudoController,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Nouveau pseudo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _isLoading ? null : _updatePseudo,
                        icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_rounded),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.user.pseudo,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 20),
                      ),
                    ],
                  ),
            const SizedBox(height: 40),

            // STATS GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Score Total', '${widget.user.totalScore}', Icons.emoji_events_rounded, Colors.amber),
                _buildStatCard('Parties', '${widget.user.gamesPlayed}', Icons.videogame_asset_rounded, Colors.blueAccent),
                _buildStatCard('Win Rate', '${winRate.toStringAsFixed(1)}%', Icons.trending_up_rounded, Colors.greenAccent),
                _buildStatCard('Amis', '12', Icons.people_alt_rounded, Colors.pinkAccent), // TODO: Dynamic count
              ],
            ),
            const SizedBox(height: 40),

            // DANGER ZONE
            OutlinedButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pop(context)),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('SE DÉCONNECTER', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
