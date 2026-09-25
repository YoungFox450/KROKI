import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  developer.log('Notification reçue en arrière-plan: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await _saveTokenForCurrentUser(await _messaging.getToken());
    _auth.authStateChanges().listen((_) async {
      await _saveTokenForCurrentUser(await _messaging.getToken());
    });

    _messaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenForCurrentUser(newToken);
    });
  }

  Future<void> _saveTokenForCurrentUser(String? token) async {
    final currentUid = _auth.currentUser?.uid;
    if (token == null || currentUid == null) return;
    await _firestore.collection('users').doc(currentUid).collection('fcmTokens').doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
