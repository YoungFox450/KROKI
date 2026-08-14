import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inscription avec Email, Mot de passe et Pseudo
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String pseudo,
  }) async {
    try {
      // 1. Création du compte dans Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // 2. Création du profil utilisateur dans Firestore
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          pseudo: pseudo.trim(),
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        return null; // Pas d'erreur
      }
      return "Échec de la création du compte";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Une erreur est survenue lors de l'inscription";
    } catch (e) {
      return e.toString();
    }
  }

  // Connexion avec Email et Mot de passe
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // Pas d'erreur
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Identifiants incorrects";
    } catch (e) {
      return e.toString();
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}