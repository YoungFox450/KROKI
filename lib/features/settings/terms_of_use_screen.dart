import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONDITIONS D\'UTILISATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.brush_rounded, size: 60, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'À PROPOS DE KROKI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(height: 12),
            const Text(
              'KROKI est une application de dessin social conçue pour connecter les gens à travers la créativité et le jeu. '
              'Le concept est simple : un joueur dessine un mot secret, et les autres doivent le deviner le plus rapidement possible.',
              style: TextStyle(height: 1.5, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const Text(
              'LE CRÉATEUR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cette application a été entièrement conçue et développée par Odrey, passionné par le développement Android '
              'et les expériences utilisateurs interactives. KROKI est le fruit d\'un travail visant à offrir une plateforme '
              'de jeu fluide, moderne et communautaire.',
              style: TextStyle(height: 1.5, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const Text(
              'RÈGLES DU JEU & CONDUITE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(height: 12),
            _buildRuleItem('1. Fair-Play', 'Il est interdit d\'écrire le mot à deviner sur le dessin. L\'essence du jeu est de dessiner.'),
            _buildRuleItem('2. Respect', 'Les pseudos et les messages dans le chat doivent rester courtois. Tout comportement abusif entraînera un bannissement.'),
            _buildRuleItem('3. Propriété', 'Les dessins créés sur la plateforme sont éphémères et servent uniquement au divertissement lors des parties.'),
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            const Text(
              'En utilisant KROKI, vous acceptez de respecter ces règles et de contribuer à une communauté saine et créative.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white38),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}
