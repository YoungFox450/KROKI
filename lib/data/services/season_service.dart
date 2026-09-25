import 'package:cloud_firestore/cloud_firestore.dart';

class SeasonService {
  final FirebaseFirestore? _firestore;
  SeasonService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  String get currentSeasonId {
    final now = DateTime.now().toUtc();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    return '${now.year}-S$quarter';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> leaderboard({int limit = 100}) {
    return firestore.collection('users').orderBy('seasonScores.$currentSeasonId', descending: true).limit(limit).snapshots();
  }
}
