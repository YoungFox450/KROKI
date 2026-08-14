import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KrokiApp());
}

class KrokiApp extends StatelessWidget {
  const KrokiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kroki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // L'utilisateur est connecté ! (Écran d'accueil temporaire)
            return Scaffold(
              appBar: AppBar(
                title: const Text('KROKI - Accueil'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bienvenue, ${snapshot.data?.email ?? "Joueur"} !',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    const Text('Prêt à dessiner et deviner ?'),
                  ],
                ),
              ),
            );
          }

          // Sinon, on affiche la page de connexion
          return const LoginScreen();
        },
      ),
    );
  }
}