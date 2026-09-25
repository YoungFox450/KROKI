import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModerationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ModerationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> reportPlayer({required String playerUid, required String reason}) async {
    final reporterUid = _auth.currentUser?.uid;
    if (reporterUid == null || reporterUid == playerUid) return;
    final cleanReason = reason.trim();
    await _firestore.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': playerUid,
      'reason': cleanReason.length > 300 ? cleanReason.substring(0, 300) : cleanReason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
