import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/drawing_stroke.dart';
import '../game/widgets/drawing_canvas.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;
  final List<DrawingStroke> _strokes = [];
  bool _notificationPrompted = false;

  void _nextStep() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_tutorial', true);
      if (mounted) context.go('/login');
    }
  }

  void _requestNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ne ratez aucun tour ! 🔔'),
        content: const Text(
          'Kroki vous envoie des rappels uniquement lorsque c\'est votre tour de dessiner ou qu\'un ami vous invite à jouer. Voulez-vous activer les notifications ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('PLUS TARD'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _notificationPrompted = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications activées avec succès ! 🎉'), backgroundColor: Colors.green),
              );
            },
            child: const Text('ACTIVER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TUTORIEL · ÉTAPE ${_step + 1}/3', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 0) ...[
                const Text(
                  '1. Le Dessin en Temps Réel',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF7C4DFF)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tracez des traits sur la toile ci-dessous. Utilisez la gomme, changez la taille ou la couleur pour exprimer votre talent !',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DrawingCanvas(
                        strokes: _strokes,
                        isDrawer: true,
                        onStrokeCompleted: (stroke) => setState(() => _strokes.add(stroke)),
                      ),
                    ),
                  ),
                ),
              ] else if (_step == 1) ...[
                const Text(
                  '2. Devinez & Marquez des Points',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF7C4DFF)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pendant qu\'un joueur dessine, tapez votre réponse dans le chat le plus vite possible pour engranger max de points !',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 50, color: Colors.amber),
                      SizedBox(height: 12),
                      Text('Exemple : "TAXI JAUNE"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Plus vous devinez vite, plus vous gagnez de points !', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                const Text(
                  '3. Culture & Notifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF7C4DFF)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jouez avec des mots en français et en lingala (Kinshasa). Activez les notifications pour ne jamais manquer une partie.',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _notificationPrompted ? null : _requestNotificationPermissionDialog,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Text(_notificationPrompted ? 'Notifications activées' : 'Autoriser les notifications'),
                ),
                const Spacer(),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _nextStep,
                child: Text(_step == 2 ? 'TERMINER & JOUER' : 'SUIVANT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
