import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'word_service.dart';
import 'drawing_service.dart';

class GameLogicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DrawingService _drawingService = DrawingService();
  Timer? _timer;

  void startTimer(String roomCode) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      var roomDoc = await _firestore.collection('rooms').doc(roomCode).get();
      if (!roomDoc.exists) {
        timer.cancel();
        return;
      }

      var data = roomDoc.data()!;
      String status = data['status'] ?? 'active';

      // Vérification déconnexion de l'hôte (Délai de 30s)
      Timestamp? hostDisconnectedAt = data['hostDisconnectedAt'];
      if (hostDisconnectedAt != null) {
        int secondsDisconnected = DateTime.now().difference(hostDisconnectedAt.toDate()).inSeconds;
        if (secondsDisconnected >= 30) {
          timer.cancel();
          await closeRoom(roomCode);
          return;
        }
      }

      if (status == 'active') {
        int timeLeft = data['timeLeft'] ?? 60;
        if (timeLeft > 0) {
          await _firestore.collection('rooms').doc(roomCode).update({
            'timeLeft': timeLeft - 1,
          });
        } else {
          timer.cancel();
          await startIntermission(roomCode);
        }
      } else if (status == 'intermission') {
        int cooldownLeft = data['cooldownLeft'] ?? 15;
        if (cooldownLeft > 0) {
          await _firestore.collection('rooms').doc(roomCode).update({
            'cooldownLeft': cooldownLeft - 1,
          });
        } else {
          timer.cancel();
          await startRound(roomCode);
        }
      }
    });
  }

  // Attribution des points (Retourne les points gagnés pour le SnackBar)
  Future<int> awardPoints({
    required String roomCode,
    required String playerUid,
    required int timeLeft,
  }) async {
    int secondsElapsed = (60 - timeLeft).clamp(0, 60);
    int intervalsPassed = secondsElapsed ~/ 8;

    double basePoints = 100.0;
    double totalDeduction = 0.0;
    final random = Random();

    for (int i = 0; i < intervalsPassed; i++) {
      double penalty = 1.0 + random.nextDouble() * (13.8 - 1.0);
      totalDeduction += penalty;
    }

    int pointsEarned = max(5, (basePoints - totalDeduction).round());

    // 1. Créditer le devineur
    await _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .doc(playerUid)
        .update({'score': FieldValue.increment(pointsEarned)});

    await _firestore.collection('rooms').doc(roomCode).update({
      'guessedPlayers': FieldValue.arrayUnion([playerUid]),
    });

    // 2. Créditer le dessinateur de +2 pts
    var roomSnap = await _firestore.collection('rooms').doc(roomCode).get();
    String? drawerUid = roomSnap.data()?['drawerUid'];

    if (drawerUid != null && drawerUid != playerUid) {
      await _firestore
          .collection('rooms')
          .doc(roomCode)
          .collection('players')
          .doc(drawerUid)
          .update({'score': FieldValue.increment(2)});
    }

    // 3. Passer en pause/intermission si tout le monde a trouvé
    var playersSnap = await _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .get();

    List<String> guessedPlayers = List<String>.from(roomSnap.data()?['guessedPlayers'] ?? []);
    int totalPlayers = playersSnap.docs.length;

    if (guessedPlayers.length >= totalPlayers - 1) {
      _timer?.cancel();
      await startIntermission(roomCode);
    }

    return pointsEarned;
  }

  // Démarrer la phase de pause (15 secondes)
  Future<void> startIntermission(String roomCode) async {
    var roomRef = _firestore.collection('rooms').doc(roomCode);
    var roomSnap = await roomRef.get();
    if (!roomSnap.exists) return;

    var roomData = roomSnap.data()!;
    int currentTurn = (roomData['currentTurn'] ?? 1) + 1;
    int maxRounds = roomData['maxRounds'] ?? 3;

    var playersSnap = await roomRef.collection('players').get();
    List<DocumentSnapshot> players = playersSnap.docs;
    if (players.isEmpty) return;

    int totalPlayers = players.length;
    int calculatedRound = ((currentTurn - 1) ~/ totalPlayers) + 1;

    // Fin de partie
    if (calculatedRound > maxRounds) {
      await roomRef.update({'status': 'ended'});
      for (var playerDoc in players) {
        int matchScore = playerDoc.data() != null && (playerDoc.data() as Map).containsKey('score')
            ? (playerDoc.data() as Map)['score']
            : 0;

        if (matchScore > 0) {
          await _firestore.collection('users').doc(playerDoc.id).set({
            'totalScore': FieldValue.increment(matchScore),
          }, SetOptions(merge: true));
        }
      }
      return;
    }

    int nextDrawerIndex = (currentTurn - 1) % totalPlayers;
    String nextDrawerUid = players[nextDrawerIndex].id;
    String nextWord = WordService.getRandomWord();

    await roomRef.update({
      'status': 'intermission',
      'cooldownLeft': 15,
      'currentWord': nextWord.toUpperCase(),
      'drawerUid': nextDrawerUid,
      'currentTurn': currentTurn,
      'currentRound': calculatedRound,
      'guessedPlayers': [],
    });

    if (FirebaseAuth.instance.currentUser?.uid == roomData['hostId']) {
      startTimer(roomCode);
    }
  }

  // Démarrer un tour de jeu (60 secondes)
  Future<void> startRound(String roomCode) async {
    await _drawingService.clearCanvas(roomCode);
    var roomRef = _firestore.collection('rooms').doc(roomCode);
    await roomRef.update({
      'status': 'active',
      'timeLeft': 60,
    });

    var roomSnap = await roomRef.get();
    if (FirebaseAuth.instance.currentUser?.uid == roomSnap.data()?['hostId']) {
      startTimer(roomCode);
    }
  }

  // Ignorer l'attente (bouton Skip du dessinateur)
  Future<void> skipCooldown(String roomCode) async {
    _timer?.cancel();
    await startRound(roomCode);
  }

  // Fermer le salon de force
  Future<void> closeRoom(String roomCode) async {
    _timer?.cancel();
    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'closed',
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }
}
