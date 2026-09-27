import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF15151B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.palette_rounded, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 30),
                const Text(
                  'BENVENUE SUR KROKI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Le jeu de dessin multijoueur aux couleurs de Kinshasa et de la culture congolaise.\nDessinez, devinez et vibrez en lingala !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), height: 1.5),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.push('/tutorial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7C4DFF),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('DÉCOUVRIR LE TUTORIEL'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Passer directement à la connexion', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
