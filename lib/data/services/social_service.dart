import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Rechercher des utilisateurs par pseudo (exact ou préfixe)
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    var snap = await _firestore
        .collection('users')
        .where('pseudo', isGreaterThanOrEqualTo: query)
        .where('pseudo', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get();

    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .where((user) => user.uid != _myUid)
        .toList();
  }

  // Envoyer une demande d'ami
  Future<void> sendFriendRequest(UserModel targetUser, String myPseudo) async {
    await _firestore.collection('friend_requests').add({
      'fromUid': _myUid,
      'fromPseudo': myPseudo,
      'toUid': targetUser.uid,
      'toPseudo': targetUser.pseudo,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Accepter une demande d'ami
  Future<void> acceptFriendRequest(String requestId, String friendUid) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Marquer la demande comme acceptée
      transaction.update(_firestore.collection('friend_requests').doc(requestId), {
        'status': 'accepted',
      });

      // 2. Créer la relation d'amitié
      transaction.set(_firestore.collection('friendships').doc(), {
        'uids': [_myUid, friendUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Refuser une demande
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  // Stream des demandes d'amis reçues
  Stream<QuerySnapshot> getIncomingRequestsStream() {
    return _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Stream de la liste d'amis
  Stream<List<UserModel>> getFriendsStream() {
    return _firestore
        .collection('friendships')
        .where('uids', arrayContains: _myUid)
        .snapshots()
        .asyncMap((snap) async {
      List<String> friendUids = [];
      for (var doc in snap.docs) {
        List<dynamic> uids = doc['uids'];
        friendUids.add(uids.firstWhere((id) => id != _myUid));
      }

      if (friendUids.isEmpty) return [];

      var usersSnap = await _firestore
          .collection('users')
          .where('uid', whereIn: friendUids)
          .get();

      return usersSnap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  // Mettre à jour la présence (Version Robuste avec Realtime DB)
  void setupPresence() {
    if (_myUid.isEmpty) return;

    final presenceRef = _database.ref('status/$_myUid');
    final userFirestoreRef = _firestore.collection('users').doc(_myUid);

    _database.ref('.info/connected').onValue.listen((event) {
      if (event.snapshot.value == true) {
        // En ligne sur Realtime DB
        presenceRef.onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        }).then((_) {
          presenceRef.set({
            'isOnline': true,
            'lastSeen': ServerValue.timestamp,
          });
        });

        // En ligne sur Firestore (pour les requêtes)
        userFirestoreRef.update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> updatePresence(bool isOnline) async {
    if (_myUid.isEmpty) return;
    await _firestore.collection('users').doc(_myUid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    await _database.ref('status/$_myUid').set({
      'isOnline': isOnline,
      'lastSeen': ServerValue.timestamp,
    });
  }
}
