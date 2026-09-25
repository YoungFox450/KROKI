import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityWordService {
  final FirebaseFirestore _firestore;
  CommunityWordService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> randomWord({String locale = 'fr'}) async {
    final snapshot = await _firestore.collection('community_words').where('locale', isEqualTo: locale).limit(50).get();
    if (snapshot.docs.isEmpty) return null;
    final value = snapshot.docs[Random().nextInt(snapshot.docs.length)].data()['word'];
    return value is String && value.trim().isNotEmpty ? value.trim().toUpperCase() : null;
  }

  Future<void> submitWord({required String word, String locale = 'fr', required String authorUid}) async {
    final cleanWord = word.trim().toUpperCase();
    if (cleanWord.length < 2 || cleanWord.length > 40) return;
    await _firestore.collection('community_words').add({
      'word': cleanWord,
      'locale': locale,
      'authorUid': authorUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
