import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Génère un code de 4 lettres aléatoires
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Créer une nouvelle salle
  Future<String?> createRoom({
    required String hostUid,
    required String hostPseudo,
  }) async {
    try {
      String code = _generateRoomCode();

      RoomModel room = RoomModel(
        code: code,
        hostId: hostUid,
      );

      // 1. Créer le document de la salle
      await _firestore.collection('rooms').doc(code).set(room.toMap());

      // 2. Ajouter l'hôte dans la sous-collection "players"
      PlayerModel hostPlayer = PlayerModel(
        uid: hostUid,
        pseudo: hostPseudo,
        isHost: true,
      );

      await _firestore
          .collection('rooms')
          .doc(code)
          .collection('players')
          .doc(hostUid)
          .set(hostPlayer.toMap());

      return code;
    } catch (e) {
      return null;
    }
  }

  // Rejoindre une salle existante
  Future<String?> joinRoom({
    required String roomCode,
    required String uid,
    required String pseudo,
  }) async {
    try {
      DocumentSnapshot roomDoc =
      await _firestore.collection('rooms').doc(roomCode).get();

      if (!roomDoc.exists) {
        return "La salle n'existe pas.";
      }

      Map<String, dynamic> data = roomDoc.data() as Map<String, dynamic>;
      if (data['status'] != 'lobby') {
        return "La partie a déjà commencé.";
      }

      PlayerModel player = PlayerModel(
        uid: uid,
        pseudo: pseudo,
        isHost: false,
      );

      await _firestore
          .collection('rooms')
          .doc(roomCode)
          .collection('players')
          .doc(uid)
          .set(player.toMap());

      return null; // Réussite
    } catch (e) {
      return e.toString();
    }
  }

  // Démarrer la partie (Passer du statut 'lobby' à 'playing')
  Future<void> startGame(String roomCode) async {
    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'playing',
    });
  }
}